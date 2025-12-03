defmodule LoteriaWeb.CantorLive do
  use LoteriaWeb, :live_view

  alias Loteria.{GameRegistry, GameServer, Cards}
  alias LoteriaWeb.Presence

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    case GameRegistry.find_game(game_id) do
      {:ok, pid} ->
        game = GameServer.get_game(pid)
        presence_topic = "presence:game:#{game_id}"
        cantor_topic = "presence:cantor:#{game_id}"

        # Generate a stable cantor_id for this session
        cantor_id = socket.id

        if connected?(socket) do
          Phoenix.PubSub.subscribe(Loteria.PubSub, "game:#{game_id}")
          Phoenix.PubSub.subscribe(Loteria.PubSub, presence_topic)

          # Track cantor presence
          Presence.track(self(), cantor_topic, "cantor", %{
            joined_at: System.system_time(:second)
          })

          # Claim cantor role (updates game state to recognize this socket.id)
          GameServer.claim_cantor(pid, cantor_id)
        end

        current_card = if game.current_card, do: Cards.get_card(game.current_card), else: nil
        presences = Presence.list(presence_topic)

        # Refresh game state after claiming
        game = GameServer.get_game(pid)

        {:ok,
         assign(socket,
           page_title: "Cantor - #{game_id}",
           game_id: game_id,
           game_pid: pid,
           game: game,
           cantor_id: cantor_id,
           current_card: current_card,
           drawn_cards: Enum.map(game.drawn, &Cards.get_card/1),
           presences: presences,
           toast: nil,
           error: nil,
           winner: nil
         )}

      {:error, :not_found} ->
        {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    case GameServer.start_game(socket.assigns.game_pid, socket.assigns.cantor_id) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game, error: nil)}

      {:error, :not_enough_players} ->
        {:noreply, assign(socket, error: "Se necesita al menos un jugador para empezar")}

      {:error, reason} ->
        {:noreply, assign(socket, error: "Error: #{reason}")}
    end
  end

  @impl true
  def handle_event("draw_card", _params, socket) do
    case GameServer.draw_card(socket.assigns.game_pid, socket.assigns.cantor_id) do
      {:ok, game, card} ->
        drawn_cards = [card | socket.assigns.drawn_cards]
        {:noreply, assign(socket, game: game, current_card: card, drawn_cards: drawn_cards)}

      {:error, :deck_empty} ->
        {:noreply, assign(socket, error: "No hay más cartas en el mazo")}

      {:error, reason} ->
        {:noreply, assign(socket, error: "Error: #{reason}")}
    end
  end

  @impl true
  def handle_event("reset_game", _params, socket) do
    case GameServer.reset_game(socket.assigns.game_pid, socket.assigns.cantor_id) do
      {:ok, game} ->
        {:noreply,
         assign(socket,
           game: game,
           current_card: nil,
           drawn_cards: [],
           winner: nil,
           error: nil
         )}

      {:error, reason} ->
        {:noreply, assign(socket, error: "Error: #{reason}")}
    end
  end

  @impl true
  def handle_info({:player_joined, %{player_id: _id, name: _name}}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:player_left, %{player_id: _id}}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:game_started, _payload}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:winner, %{player_id: _id, name: name, winning_cards: cards}}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    {:noreply, assign(socket, game: game, winner: %{name: name, cards: cards})}
  end

  @impl true
  def handle_info({:invalid_claim, _payload}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_reset, _payload}, socket) do
    game = GameServer.get_game(socket.assigns.game_pid)
    {:noreply, assign(socket, game: game, current_card: nil, drawn_cards: [], winner: nil)}
  end

  @impl true
  def handle_info({:card_drawn, _payload}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    presence_topic = "presence:game:#{socket.assigns.game_id}"
    presences = Presence.list(presence_topic)

    # Show toast for joins/leaves
    toast =
      case diff do
        %{joins: joins} when map_size(joins) > 0 ->
          {_id, %{metas: [meta | _]}} = Enum.at(joins, 0)
          %{type: :join, message: "#{meta.name} se reconectó"}

        %{leaves: leaves} when map_size(leaves) > 0 ->
          {_id, %{metas: [meta | _]}} = Enum.at(leaves, 0)
          %{type: :leave, message: "#{meta.name} se desconectó"}

        _ ->
          nil
      end

    socket =
      if toast do
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
    <div class="min-h-screen bg-gradient-to-b from-purple-600 via-pink-500 to-rose-500">
      <.toast_notification toast={@toast} />
      <header class="bg-black/20 backdrop-blur p-4">
        <div class="max-w-4xl mx-auto flex justify-between items-center">
          <.link
            navigate={~p"/"}
            class="text-2xl font-bold text-white hover:text-yellow-300 transition-colors"
          >
            LOTERÍA.LIVE
          </.link>
          <div class="flex items-center gap-4">
            <span class="text-white/80">
              Jugadores: {map_size(@game.players)}
            </span>
            <div class="bg-white/20 px-4 py-2 rounded-lg">
              <span class="text-yellow-300 font-mono font-bold">{@game_id}</span>
            </div>
          </div>
        </div>
      </header>

      <main class="max-w-4xl mx-auto p-4">
        <%= if @winner do %>
          <.winner_announcement winner={@winner} />
          <div class="text-center mt-6">
            <button
              phx-click="reset_game"
              class="bg-gradient-to-r from-yellow-400 to-orange-500 hover:from-yellow-500 hover:to-orange-600 text-white font-bold py-4 px-8 rounded-xl text-xl shadow-lg transform hover:scale-105 transition-all"
            >
              Nueva Ronda
            </button>
          </div>
        <% else %>
          <%= case @game.status do %>
            <% :lobby -> %>
              <.lobby_view game={@game} game_id={@game_id} error={@error} presences={@presences} />
            <% :playing -> %>
              <.playing_view
                current_card={@current_card}
                drawn_cards={@drawn_cards}
                deck_remaining={length(@game.deck)}
                error={@error}
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
    <div class="bg-white rounded-2xl p-8 shadow-2xl border-4 border-yellow-400">
      <h2 class="text-3xl font-bold text-purple-800 text-center mb-6">
        Sala de Espera
      </h2>

      <div class="text-center mb-8">
        <p class="text-gray-600 mb-2">Comparte este código con los jugadores:</p>
        <div class="inline-flex items-center gap-2 bg-gray-100 px-8 py-4 rounded-xl border-2 border-dashed border-gray-400">
          <span class="text-4xl font-mono font-bold text-purple-800 tracking-widest">
            {@game_id}
          </span>
          <button
            id="copy-code"
            phx-hook="CopyToClipboard"
            data-copy={@game_id}
            class="p-2 hover:bg-gray-200 rounded-lg transition-colors"
            title="Copiar código"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 text-gray-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
              />
            </svg>
          </button>
        </div>
      </div>

      <div class="mb-8">
        <h3 class="text-xl font-semibold text-gray-700 mb-4">
          Jugadores ({map_size(@game.players)})
        </h3>
        <%= if map_size(@game.players) > 0 do %>
          <ul class="space-y-2">
            <%= for {player_id, player} <- @game.players do %>
              <li class="flex items-center gap-2 text-lg text-gray-900">
                <.presence_indicator online={Map.has_key?(@presences, player_id)} />
                <span class={unless Map.has_key?(@presences, player_id), do: "opacity-50"}>
                  {player.name}
                </span>
              </li>
            <% end %>
          </ul>
        <% else %>
          <p class="text-gray-500 italic">Esperando jugadores...</p>
        <% end %>
      </div>

      <%= if @error do %>
        <div class="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded-xl text-center">
          {@error}
        </div>
      <% end %>

      <button
        phx-click="start_game"
        class="w-full bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white font-bold py-4 px-6 rounded-xl text-2xl transition-all transform hover:scale-105 shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
        disabled={map_size(@game.players) < 1}
      >
        ¡EMPEZAR!
      </button>
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
        "fixed top-4 left-1/2 -translate-x-1/2 z-50 px-4 py-2 rounded-lg shadow-lg text-white font-medium",
        if(@toast.type == :join, do: "bg-green-500", else: "bg-orange-500")
      ]}>
        {@toast.message}
      </div>
    <% end %>
    """
  end

  defp playing_view(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="bg-white rounded-2xl p-8 shadow-2xl border-4 border-yellow-400 text-center">
        <%= if @current_card do %>
          <div class="mb-6">
            <div class="text-9xl mb-4 drop-shadow-lg">
              {@current_card.emoji}
            </div>
            <h2 class="text-4xl font-bold text-purple-800 mb-2">
              {@current_card.name}
            </h2>
            <p class="text-xl text-gray-600 italic">
              "{@current_card.dicho}"
            </p>
          </div>
        <% else %>
          <div class="py-12">
            <p class="text-2xl text-gray-500">
              Presiona "Siguiente" para sacar la primera carta
            </p>
          </div>
        <% end %>

        <%= if @error do %>
          <div class="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded-xl">
            {@error}
          </div>
        <% end %>

        <button
          phx-click="draw_card"
          class="bg-gradient-to-r from-pink-500 to-rose-500 hover:from-pink-600 hover:to-rose-600 text-white font-bold py-4 px-12 rounded-xl text-2xl transition-all transform hover:scale-105 shadow-lg disabled:opacity-50"
          disabled={@deck_remaining == 0}
        >
          ◀ SIGUIENTE ▶
        </button>

        <p class="mt-4 text-gray-500">
          Cartas restantes: {@deck_remaining}
        </p>
      </div>

      <%= if length(@drawn_cards) > 0 do %>
        <div class="bg-white rounded-xl p-4 shadow-lg">
          <h3 class="text-lg font-semibold text-gray-700 mb-3">Historial:</h3>
          <div class="flex gap-2 overflow-x-auto pb-2">
            <%= for card <- Enum.reverse(@drawn_cards) do %>
              <div
                class="flex-shrink-0 w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center text-2xl border-2 border-gray-300"
                title={card.name}
              >
                {card.emoji}
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp winner_announcement(assigns) do
    ~H"""
    <div class="bg-gradient-to-r from-yellow-400 via-orange-500 to-red-500 rounded-2xl p-8 shadow-2xl text-center animate-pulse">
      <div class="text-6xl mb-4">🎉</div>
      <h2 class="text-4xl font-bold text-white mb-4">
        ¡LOTERÍA!
      </h2>
      <p class="text-2xl text-white mb-4">
        <span class="font-bold">{@winner.name}</span> ha ganado!
      </p>
      <div class="flex justify-center gap-3 flex-wrap">
        <%= for card_id <- @winner.cards do %>
          <% card = Cards.get_card(card_id) %>
          <div class="bg-white/90 rounded-lg p-3 text-3xl">
            {card.emoji}
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
