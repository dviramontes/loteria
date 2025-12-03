defmodule LoteriaWeb.PlayerLive do
  use LoteriaWeb, :live_view

  alias Loteria.{GameRegistry, GameServer, Cards}
  alias LoteriaWeb.Presence

  @impl true
  def mount(%{"id" => game_id} = params, _session, socket) do
    player_name = params["name"] || "Jugador"

    case GameRegistry.find_game(game_id) do
      {:ok, pid} ->
        # Use stable player_id based on game + name so refreshes don't create new players
        player_id = generate_player_id(game_id, player_name)

        if connected?(socket) do
          # Subscribe to game events
          Phoenix.PubSub.subscribe(Loteria.PubSub, "game:#{game_id}")

          # Track presence for this player
          presence_topic = "presence:game:#{game_id}"
          Phoenix.PubSub.subscribe(Loteria.PubSub, presence_topic)

          Presence.track(self(), presence_topic, player_id, %{
            name: player_name,
            joined_at: System.system_time(:second)
          })

          case GameServer.join(pid, player_id, player_name) do
            {:ok, _game} -> :ok
            {:error, :already_joined} -> :ok
            {:error, :game_already_started} -> :ok
            {:error, _} -> :ok
          end
        end

        game = GameServer.get_game(pid)
        player = game.players[player_id]
        current_card = if game.current_card, do: Cards.get_card(game.current_card), else: nil

        # Get initial presences
        presence_topic = "presence:game:#{game_id}"
        presences = Presence.list(presence_topic)

        {:ok,
         assign(socket,
           page_title: "Jugador - #{game_id}",
           game_id: game_id,
           game_pid: pid,
           game: game,
           player_id: player_id,
           player_name: player_name,
           player: player,
           current_card: current_card,
           presences: presences,
           toast: nil,
           error: nil,
           winner: nil,
           claim_error: false
         )}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "No se encontró el juego")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("toggle_card", %{"card-id" => card_id_str}, socket) do
    card_id = String.to_integer(card_id_str)

    case GameServer.toggle_mark(socket.assigns.game_pid, socket.assigns.player_id, card_id) do
      {:ok, game, _action} ->
        player = game.players[socket.assigns.player_id]
        {:noreply, assign(socket, game: game, player: player)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("claim_loteria", _params, socket) do
    case GameServer.claim_loteria(socket.assigns.game_pid, socket.assigns.player_id) do
      {:ok, game, _winning_cards} ->
        {:noreply, assign(socket, game: game)}

      {:error, :invalid_claim} ->
        {:noreply, assign(socket, claim_error: true)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:player_joined, _payload}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:player_left, _payload}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:game_started, %{tablas: _tablas}}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    player = game.players[socket.assigns.player_id]
    {:noreply, assign(socket, game: game, player: player)}
  end

  @impl true
  def handle_info({:card_drawn, %{card_id: _id, card: card}}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    {:noreply, assign(socket, game: game, current_card: card, claim_error: false)}
  end

  @impl true
  def handle_info({:winner, %{player_id: winner_id, name: name, winning_cards: cards}}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    is_winner = winner_id == socket.assigns.player_id
    {:noreply, assign(socket, game: game, winner: %{name: name, cards: cards, is_me: is_winner})}
  end

  @impl true
  def handle_info({:invalid_claim, %{player_id: player_id}}, socket) do
    if player_id == socket.assigns.player_id do
      {:noreply, assign(socket, claim_error: true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:game_reset, _payload}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    player = game.players[socket.assigns.player_id]

    {:noreply,
     assign(socket,
       game: game,
       player: player,
       current_card: nil,
       winner: nil,
       claim_error: false
     )}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    presence_topic = "presence:game:#{socket.assigns.game_id}"
    presences = Presence.list(presence_topic)

    # Show toast for joins (reconnections)
    toast =
      case diff do
        %{joins: joins} when map_size(joins) > 0 ->
          # Get the first joiner's name (usually just one at a time)
          {_id, %{metas: [meta | _]}} = Enum.at(joins, 0)
          # Don't show toast for self
          if meta.name != socket.assigns.player_name do
            %{type: :join, message: "#{meta.name} se reconectó"}
          else
            nil
          end

        %{leaves: leaves} when map_size(leaves) > 0 ->
          {_id, %{metas: [meta | _]}} = Enum.at(leaves, 0)

          if meta.name != socket.assigns.player_name do
            %{type: :leave, message: "#{meta.name} se desconectó"}
          else
            nil
          end

        _ ->
          nil
      end

    socket =
      if toast do
        # Clear toast after 3 seconds
        Process.send_after(self(), :clear_toast, 3000)
        assign(socket, presences: presences, toast: toast)
      else
        assign(socket, presences: presences)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:clear_toast, socket) do
    {:noreply, assign(socket, toast: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-teal-500 via-cyan-500 to-blue-600">
      <.toast_notification toast={@toast} />
      <header class="bg-black/20 backdrop-blur p-4">
        <div class="max-w-lg mx-auto flex justify-between items-center">
          <.link
            navigate={~p"/"}
            class="text-xl font-bold text-white hover:text-yellow-300 transition-colors"
          >
            LOTERÍA.LIVE
          </.link>
          <%= if @current_card do %>
            <div class="flex items-center gap-2 bg-white/20 px-3 py-1 rounded-lg">
              <span class="text-2xl">{@current_card.emoji}</span>
              <span class="text-white font-semibold">{@current_card.name}</span>
            </div>
          <% end %>
        </div>
      </header>

      <main class="max-w-lg mx-auto p-4">
        <%= if @winner do %>
          <.winner_announcement winner={@winner} />
        <% else %>
          <%= case @game.status do %>
            <% :lobby -> %>
              <.lobby_view game={@game} player_name={@player_name} presences={@presences} />
            <% :playing -> %>
              <.playing_view
                player={@player}
                game={@game}
                current_card={@current_card}
                claim_error={@claim_error}
              />
            <% :finished -> %>
              <div class="text-center text-white text-2xl">
                El juego ha terminado
              </div>
          <% end %>
        <% end %>
      </main>
    </div>
    """
  end

  defp lobby_view(assigns) do
    ~H"""
    <div class="bg-white/90 backdrop-blur rounded-2xl p-8 shadow-2xl border-4 border-teal-400 text-center">
      <h2 class="text-3xl font-bold text-teal-800 mb-6">
        ¡Bienvenido, {@player_name}!
      </h2>

      <div class="mb-8">
        <div class="inline-block animate-pulse">
          <div class="text-6xl mb-4">🎴</div>
        </div>
        <p class="text-xl text-gray-600">
          Esperando a que el Cantor inicie el juego...
        </p>
      </div>

      <div class="bg-gray-100 rounded-xl p-4">
        <h3 class="text-lg font-semibold text-gray-700 mb-3">
          Jugadores en la sala ({map_size(@game.players)})
        </h3>
        <ul class="space-y-2">
          <%= for {player_id, player} <- @game.players do %>
            <li class="flex items-center justify-center gap-2 text-gray-600">
              <.presence_indicator online={Map.has_key?(@presences, player_id)} />
              <%= if player.name == @player_name do %>
                <span class="font-bold text-teal-600">{player.name} (tú)</span>
              <% else %>
                <span class={unless Map.has_key?(@presences, player_id), do: "opacity-50"}>
                  {player.name}
                </span>
              <% end %>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  defp presence_indicator(assigns) do
    ~H"""
    <span class={[
      "inline-block w-2 h-2 rounded-full",
      if(@online, do: "bg-green-500", else: "bg-gray-400")
    ]}>
    </span>
    """
  end

  defp toast_notification(assigns) do
    ~H"""
    <%= if @toast do %>
      <div class={[
        "fixed top-4 left-1/2 -translate-x-1/2 z-50 px-4 py-2 rounded-lg shadow-lg text-white font-medium animate-fade-in",
        if(@toast.type == :join, do: "bg-green-500", else: "bg-orange-500")
      ]}>
        {@toast.message}
      </div>
    <% end %>
    """
  end

  defp playing_view(assigns) do
    ~H"""
    <div class="space-y-4">
      <%= if @claim_error do %>
        <div class="bg-red-100 border-2 border-red-400 text-red-700 rounded-xl p-4 text-center animate-shake">
          ¡Aún no tienes línea completa! Sigue jugando.
        </div>
      <% end %>

      <div class="bg-white/90 backdrop-blur rounded-2xl p-4 shadow-2xl border-4 border-teal-400">
        <%= if @player do %>
          <.tabla player={@player} drawn={@game.drawn} />
        <% else %>
          <p class="text-center text-gray-500 py-8">
            Esperando tu tabla...
          </p>
        <% end %>
      </div>

      <button
        phx-click="claim_loteria"
        class="w-full bg-gradient-to-r from-yellow-400 via-orange-500 to-red-500 hover:from-yellow-500 hover:via-orange-600 hover:to-red-600 text-white font-bold py-5 px-6 rounded-xl text-2xl transition-all transform hover:scale-105 shadow-lg"
      >
        ¡LOTERÍA! 🎉
      </button>
    </div>
    """
  end

  defp tabla(assigns) do
    ~H"""
    <div class="grid grid-cols-4 gap-2">
      <%= for {card_id, index} <- Enum.with_index(@player.tabla) do %>
        <% card = Cards.get_card(card_id) %>
        <% is_marked = MapSet.member?(@player.marked, card_id) %>
        <% is_drawn = card_id in @drawn %>
        <button
          id={"card-#{index}"}
          phx-hook="CardSound"
          phx-click="toggle_card"
          phx-value-card-id={card_id}
          class={[
            "aspect-square rounded-xl flex flex-col items-center justify-center p-1 transition-all transform active:scale-95 border-2",
            if(is_marked,
              do: "bg-green-100 border-green-500 shadow-inner",
              else: "bg-white border-gray-300 hover:border-teal-400"
            ),
            if(is_drawn && !is_marked, do: "ring-2 ring-yellow-400 animate-pulse", else: "")
          ]}
        >
          <span class="text-3xl md:text-4xl">{card.emoji}</span>
          <%= if is_marked do %>
            <span class="absolute text-4xl opacity-60">●</span>
          <% end %>
        </button>
      <% end %>
    </div>
    """
  end

  defp winner_announcement(assigns) do
    ~H"""
    <div
      id="winner-celebration"
      phx-hook="WinnerCelebration"
      class={[
        "rounded-2xl p-8 shadow-2xl text-center",
        if(@winner.is_me,
          do: "bg-gradient-to-r from-yellow-400 via-orange-500 to-red-500 animate-pulse",
          else: "bg-white/90"
        )
      ]}
    >
      <div class="text-6xl mb-4">
        {if @winner.is_me, do: "🏆", else: "👏"}
      </div>
      <h2 class={[
        "text-4xl font-bold mb-4",
        if(@winner.is_me, do: "text-white", else: "text-purple-800")
      ]}>
        <%= if @winner.is_me do %>
          ¡GANASTE!
        <% else %>
          ¡LOTERÍA!
        <% end %>
      </h2>
      <p class={[
        "text-2xl mb-4",
        if(@winner.is_me, do: "text-white", else: "text-gray-600")
      ]}>
        <%= if @winner.is_me do %>
          ¡Felicidades!
        <% else %>
          <span class="font-bold">{@winner.name}</span> ha ganado
        <% end %>
      </p>
      <div class="flex justify-center gap-3 flex-wrap">
        <%= for card_id <- @winner.cards do %>
          <% card = Cards.get_card(card_id) %>
          <div class="bg-white/90 rounded-lg p-3 text-3xl shadow">
            {card.emoji}
          </div>
        <% end %>
      </div>

      <p class={[
        "mt-6 text-lg",
        if(@winner.is_me, do: "text-white/80", else: "text-gray-500")
      ]}>
        Esperando nueva ronda...
      </p>
    </div>
    """
  end

  # Generate a stable player_id from game_id and player_name
  # This ensures the same player doesn't get duplicated on page refresh
  defp generate_player_id(game_id, player_name) do
    :crypto.hash(:sha256, "#{game_id}:#{player_name}")
    |> Base.encode16(case: :lower)
    |> binary_part(0, 16)
  end
end
