defmodule Loteria.GameRegistry do
  @moduledoc """
  Registry and supervisor for active Lotería games.
  Uses a Registry for game lookups and a DynamicSupervisor for game processes.
  """

  alias Loteria.GameServer

  @registry_name __MODULE__.Registry
  @supervisor_name __MODULE__.Supervisor

  @doc """
  Starts the registry and supervisor as part of the application supervision tree.
  Returns child specifications for the application supervisor.
  """
  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def start_link do
    children = [
      {Registry, keys: :unique, name: @registry_name},
      {DynamicSupervisor, name: @supervisor_name, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_all, name: __MODULE__)
  end

  @doc """
  Creates a new game with the given cantor ID.
  Returns {:ok, game_id, pid} or {:error, reason}.
  """
  def create_game(cantor_id) do
    # GameServer now registers itself in init/1
    case DynamicSupervisor.start_child(@supervisor_name, {GameServer, cantor_id}) do
      {:ok, pid} ->
        game = GameServer.get_game(pid)
        {:ok, game.id, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns the registry name for GameServer to use during init.
  """
  def registry_name, do: @registry_name

  @doc """
  Finds a game by its room code.
  Returns {:ok, pid} or {:error, :not_found}.
  """
  def find_game(game_id) do
    case Registry.lookup(@registry_name, game_id) do
      [{_owner_pid, game_pid}] ->
        {:ok, game_pid}

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Gets a game by its room code, returning the game state.
  Returns {:ok, game} or {:error, :not_found}.
  """
  def get_game(game_id) do
    case find_game(game_id) do
      {:ok, pid} ->
        {:ok, GameServer.get_game(pid)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Lists all active game IDs.
  """
  def list_games do
    Registry.select(@registry_name, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @doc """
  Counts active games.
  """
  def count_games do
    length(list_games())
  end
end
