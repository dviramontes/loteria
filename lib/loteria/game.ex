defmodule Loteria.Game do
  @moduledoc """
  Game state structure and operations for Lotería.
  """

  alias Loteria.Cards

  defstruct [
    :id,
    :status,
    :cantor_id,
    :players,
    :deck,
    :drawn,
    :current_card,
    :winner,
    :created_at
  ]

  @type status :: :lobby | :playing | :finished
  @type t :: %__MODULE__{
          id: String.t(),
          status: status(),
          cantor_id: String.t(),
          players: %{String.t() => Player.t()},
          deck: [integer()],
          drawn: [integer()],
          current_card: integer() | nil,
          winner: String.t() | nil,
          created_at: DateTime.t()
        }

  defmodule Player do
    @moduledoc """
    Player state within a Lotería game.
    """
    defstruct [:id, :name, :tabla, :marked]

    @type t :: %__MODULE__{
            id: String.t(),
            name: String.t(),
            tabla: [integer()],
            marked: MapSet.t(integer())
          }

    def new(id, name) do
      %__MODULE__{
        id: id,
        name: name,
        tabla: [],
        marked: MapSet.new()
      }
    end

    def assign_tabla(%__MODULE__{} = player) do
      %{player | tabla: Cards.random_tabla()}
    end
  end

  @doc """
  Creates a new game with the given cantor (game master).
  """
  def new(cantor_id) do
    %__MODULE__{
      id: generate_room_code(),
      status: :lobby,
      cantor_id: cantor_id,
      players: %{},
      deck: [],
      drawn: [],
      current_card: nil,
      winner: nil,
      created_at: DateTime.utc_now()
    }
  end

  @doc """
  Adds a player to the game lobby.
  """
  def add_player(%__MODULE__{status: :lobby} = game, player_id, player_name) do
    if Map.has_key?(game.players, player_id) do
      {:error, :already_joined}
    else
      player = Player.new(player_id, player_name)
      {:ok, %{game | players: Map.put(game.players, player_id, player)}}
    end
  end

  def add_player(%__MODULE__{}, _player_id, _player_name) do
    {:error, :game_already_started}
  end

  @doc """
  Removes a player from the game.
  """
  def remove_player(%__MODULE__{} = game, player_id) do
    {:ok, %{game | players: Map.delete(game.players, player_id)}}
  end

  @doc """
  Starts the game. Only the cantor can start the game.
  Assigns tablas to all players and shuffles the deck.
  """
  def start_game(%__MODULE__{status: :lobby, cantor_id: cantor_id} = game, cantor_id) do
    if map_size(game.players) < 1 do
      {:error, :not_enough_players}
    else
      players =
        game.players
        |> Enum.map(fn {id, player} -> {id, Player.assign_tabla(player)} end)
        |> Map.new()

      {:ok,
       %{
         game
         | status: :playing,
           players: players,
           deck: Cards.shuffled_deck(),
           drawn: [],
           current_card: nil
       }}
    end
  end

  def start_game(%__MODULE__{status: :lobby}, _caller_id) do
    {:error, :not_cantor}
  end

  def start_game(%__MODULE__{}, _caller_id) do
    {:error, :game_already_started}
  end

  @doc """
  Draws the next card from the deck. Only the cantor can draw cards.
  """
  def draw_card(
        %__MODULE__{status: :playing, cantor_id: cantor_id, deck: [next | rest]} = game,
        cantor_id
      ) do
    {:ok,
     %{
       game
       | deck: rest,
         current_card: next,
         drawn: [next | game.drawn]
     }}
  end

  def draw_card(%__MODULE__{status: :playing, deck: []}, _caller_id) do
    {:error, :deck_empty}
  end

  def draw_card(%__MODULE__{status: :playing}, _caller_id) do
    {:error, :not_cantor}
  end

  def draw_card(%__MODULE__{}, _caller_id) do
    {:error, :game_not_started}
  end

  @doc """
  Marks a card on a player's tabla.
  """
  def mark_card(%__MODULE__{status: :playing} = game, player_id, card_id) do
    case Map.get(game.players, player_id) do
      nil ->
        {:error, :player_not_found}

      player ->
        if card_id in player.tabla do
          updated_player = %{player | marked: MapSet.put(player.marked, card_id)}
          {:ok, %{game | players: Map.put(game.players, player_id, updated_player)}}
        else
          {:error, :card_not_in_tabla}
        end
    end
  end

  def mark_card(%__MODULE__{}, _player_id, _card_id) do
    {:error, :game_not_started}
  end

  @doc """
  Unmarks a card on a player's tabla.
  """
  def unmark_card(%__MODULE__{status: :playing} = game, player_id, card_id) do
    case Map.get(game.players, player_id) do
      nil ->
        {:error, :player_not_found}

      player ->
        updated_player = %{player | marked: MapSet.delete(player.marked, card_id)}
        {:ok, %{game | players: Map.put(game.players, player_id, updated_player)}}
    end
  end

  def unmark_card(%__MODULE__{}, _player_id, _card_id) do
    {:error, :game_not_started}
  end

  @doc """
  Claims a Lotería win. Validates that the player has a valid winning line.
  """
  def claim_loteria(%__MODULE__{status: :playing} = game, player_id) do
    case Map.get(game.players, player_id) do
      nil ->
        {:error, :player_not_found}

      player ->
        case check_win(player, game.drawn) do
          {:ok, winning_cards} ->
            {:ok, %{game | status: :finished, winner: player_id}, winning_cards}

          :no_win ->
            {:error, :invalid_claim}
        end
    end
  end

  def claim_loteria(%__MODULE__{}, _player_id) do
    {:error, :game_not_started}
  end

  @doc """
  Resets the game for a new round, keeping the same players but reshuffling tablas.
  """
  def reset_game(%__MODULE__{cantor_id: cantor_id} = game, cantor_id) do
    players =
      game.players
      |> Enum.map(fn {id, player} ->
        {id, %{Player.assign_tabla(player) | marked: MapSet.new()}}
      end)
      |> Map.new()

    {:ok,
     %{
       game
       | status: :lobby,
         players: players,
         deck: [],
         drawn: [],
         current_card: nil,
         winner: nil
     }}
  end

  def reset_game(%__MODULE__{}, _caller_id) do
    {:error, :not_cantor}
  end

  @doc """
  Check if a player has a valid winning line.
  Returns {:ok, winning_cards} or :no_win
  """
  def check_win(%Player{tabla: tabla, marked: marked}, drawn) do
    rows = [
      [0, 1, 2, 3],
      [4, 5, 6, 7],
      [8, 9, 10, 11],
      [12, 13, 14, 15]
    ]

    cols = [
      [0, 4, 8, 12],
      [1, 5, 9, 13],
      [2, 6, 10, 14],
      [3, 7, 11, 15]
    ]

    lines = rows ++ cols
    drawn_set = MapSet.new(drawn)

    winning_line =
      Enum.find(lines, fn indices ->
        cards = Enum.map(indices, &Enum.at(tabla, &1))

        Enum.all?(cards, fn card_id ->
          MapSet.member?(marked, card_id) and MapSet.member?(drawn_set, card_id)
        end)
      end)

    case winning_line do
      nil -> :no_win
      indices -> {:ok, Enum.map(indices, &Enum.at(tabla, &1))}
    end
  end

  @doc """
  Returns the player count.
  """
  def player_count(%__MODULE__{players: players}), do: map_size(players)

  @doc """
  Checks if a player is in the game.
  """
  def player_in_game?(%__MODULE__{players: players}, player_id) do
    Map.has_key?(players, player_id)
  end

  @doc """
  Checks if the given player is the cantor.
  """
  def is_cantor?(%__MODULE__{cantor_id: cantor_id}, player_id) do
    cantor_id == player_id
  end

  @doc """
  Gets a player by ID.
  """
  def get_player(%__MODULE__{players: players}, player_id) do
    Map.get(players, player_id)
  end

  # Private functions

  defp generate_room_code do
    letters = Enum.map(1..3, fn _ -> Enum.random(?A..?Z) end) |> List.to_string()
    numbers = Enum.map(1..3, fn _ -> Enum.random(?0..?9) end) |> List.to_string()
    "#{letters}-#{numbers}"
  end
end
