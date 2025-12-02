defmodule LoteriaWeb.HomeLive do
  use LoteriaWeb, :live_view

  alias Loteria.GameRegistry

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Loteria.live",
       join_code: "",
       player_name: "",
       error: nil
     )}
  end

  @impl true
  def handle_event("create_game", _params, socket) do
    cantor_id = socket.id

    case GameRegistry.create_game(cantor_id) do
      {:ok, game_id, _pid} ->
        {:noreply, push_navigate(socket, to: ~p"/game/#{game_id}/cantor")}

      {:error, _reason} ->
        {:noreply, assign(socket, error: "No se pudo crear el juego. Intenta de nuevo.")}
    end
  end

  @impl true
  def handle_event("validate_join", %{"code" => code, "name" => name}, socket) do
    {:noreply, assign(socket, join_code: String.upcase(code), player_name: name, error: nil)}
  end

  @impl true
  def handle_event("join_game", %{"code" => code, "name" => name}, socket) do
    game_id = String.upcase(String.trim(code))
    player_name = String.trim(name)

    cond do
      String.length(player_name) < 1 ->
        {:noreply, assign(socket, error: "Por favor ingresa tu nombre")}

      String.length(game_id) < 1 ->
        {:noreply, assign(socket, error: "Por favor ingresa el código de la sala")}

      true ->
        case GameRegistry.find_game(game_id) do
          {:ok, _pid} ->
            {:noreply,
             push_navigate(socket,
               to: ~p"/game/#{game_id}/play?name=#{URI.encode(player_name)}"
             )}

          {:error, :not_found} ->
            {:noreply, assign(socket, error: "No se encontró el juego con ese código")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-pink-500 via-purple-500 to-blue-600 flex flex-col items-center justify-center p-4">
      <div class="text-center mb-8">
        <h1 class="text-6xl md:text-8xl font-bold text-white drop-shadow-lg mb-2 font-serif">
          LOTERÍA
        </h1>
        <p class="text-xl md:text-2xl text-yellow-300 font-semibold">
          Un juego tradicional mexicano
        </p>
      </div>

      <div class="w-full max-w-md space-y-6">
        <div class="bg-white/90 backdrop-blur rounded-2xl p-6 shadow-2xl border-4 border-yellow-400">
          <h2 class="text-2xl font-bold text-purple-800 mb-4 text-center">
            Crear Juego Nuevo
          </h2>
          <p class="text-gray-600 text-center mb-4">
            Conviértete en el Cantor y controla el juego
          </p>
          <button
            phx-click="create_game"
            class="w-full bg-gradient-to-r from-pink-500 to-rose-500 hover:from-pink-600 hover:to-rose-600 text-white font-bold py-4 px-6 rounded-xl text-xl transition-all transform hover:scale-105 shadow-lg"
          >
            Ser Cantor
          </button>
        </div>

        <div class="flex items-center gap-4">
          <div class="flex-1 h-px bg-white/50"></div>
          <span class="text-white font-semibold">o</span>
          <div class="flex-1 h-px bg-white/50"></div>
        </div>

        <div class="bg-white/90 backdrop-blur rounded-2xl p-6 shadow-2xl border-4 border-teal-400">
          <h2 class="text-2xl font-bold text-teal-800 mb-4 text-center">
            Unirse a un Juego
          </h2>

          <.form
            for={%{}}
            phx-submit="join_game"
            phx-change="validate_join"
            class="space-y-4"
          >
            <div>
              <label class="block text-gray-700 font-semibold mb-2">Tu nombre</label>
              <input
                type="text"
                name="name"
                value={@player_name}
                placeholder="Escribe tu nombre..."
                maxlength="20"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-300 focus:border-teal-500 focus:ring focus:ring-teal-200 text-lg bg-white text-gray-900 placeholder-gray-400"
              />
            </div>

            <div>
              <label class="block text-gray-700 font-semibold mb-2">Código de sala</label>
              <input
                type="text"
                name="code"
                value={@join_code}
                placeholder="ABC-123"
                maxlength="7"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-300 focus:border-teal-500 focus:ring focus:ring-teal-200 text-lg uppercase text-center tracking-widest font-mono bg-white text-gray-900 placeholder-gray-400"
              />
            </div>

            <button
              type="submit"
              class="w-full bg-gradient-to-r from-teal-500 to-cyan-500 hover:from-teal-600 hover:to-cyan-600 text-white font-bold py-4 px-6 rounded-xl text-xl transition-all transform hover:scale-105 shadow-lg"
            >
              Jugar
            </button>
          </.form>

          <%= if @error do %>
            <div class="mt-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded-xl text-center">
              {@error}
            </div>
          <% end %>
        </div>
      </div>

      <div class="mt-8 flex gap-6 text-4xl">
        <span class="animate-bounce" style="animation-delay: 0s;">🐓</span>
        <span class="animate-bounce" style="animation-delay: 0.1s;">🌙</span>
        <span class="animate-bounce" style="animation-delay: 0.2s;">💀</span>
        <span class="animate-bounce" style="animation-delay: 0.3s;">🦜</span>
        <span class="animate-bounce" style="animation-delay: 0.4s;">⭐</span>
      </div>
    </div>
    """
  end
end
