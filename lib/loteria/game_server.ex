defmodule Loteria.GameServer do
  @moduledoc """
  GenServer that manages the state of a single Lotería game.
  Uses Phoenix.PubSub to broadcast game events to all connected players.
  """

  use GenServer

  alias Loteria.Game
  alias Loteria.Cards

  @timeout :timer.hours(2)

  # Client API

  @doc """
  Starts a new game server with the given cantor.
  """
  def start_link(cantor_id) do
    GenServer.start_link(__MODULE__, cantor_id)
  end

  @doc """
  Gets the current game state.
  """
  def get_game(pid) do
    GenServer.call(pid, :get_game)
  end

  @doc """
  Adds a player to the game.
  """
  def join(pid, player_id, player_name) do
    GenServer.call(pid, {:join, player_id, player_name})
  end

  @doc """
  Removes a player from the game.
  """
  def leave(pid, player_id) do
    GenServer.call(pid, {:leave, player_id})
  end

  @doc """
  Starts the game (cantor only).
  """
  def start_game(pid, caller_id) do
    GenServer.call(pid, {:start_game, caller_id})
  end

  @doc """
  Draws the next card (cantor only).
  """
  def draw_card(pid, caller_id) do
    GenServer.call(pid, {:draw_card, caller_id})
  end

  @doc """
  Toggles a card mark on a player's tabla.
  """
  def toggle_mark(pid, player_id, card_id) do
    GenServer.call(pid, {:toggle_mark, player_id, card_id})
  end

  @doc """
  Claims a Lotería win.
  """
  def claim_loteria(pid, player_id) do
    GenServer.call(pid, {:claim_loteria, player_id})
  end

  @doc """
  Resets the game for a new round.
  """
  def reset_game(pid, caller_id) do
    GenServer.call(pid, {:reset_game, caller_id})
  end

  # Server Callbacks

  @impl true
  def init(cantor_id) do
    game = Game.new(cantor_id)
    # Register this process in the GameRegistry so it can be found by game_id
    Registry.register(Loteria.GameRegistry.registry_name(), game.id, self())
    {:ok, game, @timeout}
  end

  @impl true
  def handle_call(:get_game, _from, game) do
    {:reply, game, game, @timeout}
  end

  @impl true
  def handle_call({:join, player_id, player_name}, _from, game) do
    case Game.add_player(game, player_id, player_name) do
      {:ok, updated_game} ->
        broadcast(updated_game.id, :player_joined, %{
          player_id: player_id,
          name: player_name
        })

        {:reply, {:ok, updated_game}, updated_game, @timeout}

      {:error, reason} ->
        {:reply, {:error, reason}, game, @timeout}
    end
  end

  @impl true
  def handle_call({:leave, player_id}, _from, game) do
    {:ok, updated_game} = Game.remove_player(game, player_id)
    broadcast(updated_game.id, :player_left, %{player_id: player_id})
    {:reply, {:ok, updated_game}, updated_game, @timeout}
  end

  @impl true
  def handle_call({:start_game, caller_id}, _from, game) do
    case Game.start_game(game, caller_id) do
      {:ok, updated_game} ->
        tablas =
          updated_game.players
          |> Enum.map(fn {id, player} -> {id, player.tabla} end)
          |> Map.new()

        broadcast(updated_game.id, :game_started, %{tablas: tablas})
        {:reply, {:ok, updated_game}, updated_game, @timeout}

      {:error, reason} ->
        {:reply, {:error, reason}, game, @timeout}
    end
  end

  @impl true
  def handle_call({:draw_card, caller_id}, _from, game) do
    case Game.draw_card(game, caller_id) do
      {:ok, updated_game} ->
        card = Cards.get_card(updated_game.current_card)

        broadcast(updated_game.id, :card_drawn, %{
          card_id: updated_game.current_card,
          card: card
        })

        {:reply, {:ok, updated_game, card}, updated_game, @timeout}

      {:error, reason} ->
        {:reply, {:error, reason}, game, @timeout}
    end
  end

  @impl true
  def handle_call({:toggle_mark, player_id, card_id}, _from, game) do
    player = Game.get_player(game, player_id)

    if player && MapSet.member?(player.marked, card_id) do
      case Game.unmark_card(game, player_id, card_id) do
        {:ok, updated_game} ->
          {:reply, {:ok, updated_game, :unmarked}, updated_game, @timeout}

        {:error, reason} ->
          {:reply, {:error, reason}, game, @timeout}
      end
    else
      case Game.mark_card(game, player_id, card_id) do
        {:ok, updated_game} ->
          {:reply, {:ok, updated_game, :marked}, updated_game, @timeout}

        {:error, reason} ->
          {:reply, {:error, reason}, game, @timeout}
      end
    end
  end

  @impl true
  def handle_call({:claim_loteria, player_id}, _from, game) do
    player = Game.get_player(game, player_id)

    case Game.claim_loteria(game, player_id) do
      {:ok, updated_game, winning_cards} ->
        broadcast(updated_game.id, :winner, %{
          player_id: player_id,
          name: player.name,
          winning_cards: winning_cards
        })

        {:reply, {:ok, updated_game, winning_cards}, updated_game, @timeout}

      {:error, :invalid_claim} ->
        broadcast(game.id, :invalid_claim, %{player_id: player_id})
        {:reply, {:error, :invalid_claim}, game, @timeout}

      {:error, reason} ->
        {:reply, {:error, reason}, game, @timeout}
    end
  end

  @impl true
  def handle_call({:reset_game, caller_id}, _from, game) do
    case Game.reset_game(game, caller_id) do
      {:ok, updated_game} ->
        broadcast(updated_game.id, :game_reset, %{})
        {:reply, {:ok, updated_game}, updated_game, @timeout}

      {:error, reason} ->
        {:reply, {:error, reason}, game, @timeout}
    end
  end

  @impl true
  def handle_info(:timeout, game) do
    {:stop, :normal, game}
  end

  # Private functions

  defp broadcast(game_id, event, payload) do
    Phoenix.PubSub.broadcast(Loteria.PubSub, "game:#{game_id}", {event, payload})
  end
end
