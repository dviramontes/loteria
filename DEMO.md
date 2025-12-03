# Lotería Demo Cheat Sheet

## Connect to Running Node

```elixir
# From Fly.io
fly ssh console --app loteria -C "/app/bin/loteria remote"

# Or use justfile
just connect
```

## System Overview

```elixir
# Total process count
Process.list() |> length()
# "This app has X processes running right now"

# Memory usage (MB)
:erlang.memory() |> Keyword.get(:total) |> div(1_000_000)

# Process count
:erlang.system_info(:process_count)

# Uptime
:erlang.statistics(:wall_clock) |> elem(0) |> div(1000)  # seconds
```

## Find Active Games

```elixir
# List all active game IDs
Loteria.GameRegistry.list_games()

# Count active games
Loteria.GameRegistry.count_games()

# See full registry entries (game_id, owner_pid, game_pid)
Registry.select(Loteria.GameRegistry.Registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])

# Find a specific game by room code
Loteria.GameRegistry.find_game("ABC-123")
# => {:ok, #PID<0.1234.0>}

# Get full game state by room code
Loteria.GameRegistry.get_game("ABC-123")
# => {:ok, %Loteria.Game{...}}
```

## Inspect Game State

```elixir
# Get the pid first
{:ok, pid} = Loteria.GameRegistry.find_game("ABC-123")

# View full GenServer state
:sys.get_state(pid)

# Or use the GameServer API
Loteria.GameServer.get_game(pid)
```

## PubSub Subscriptions

```elixir
# Check PubSub node name
Phoenix.PubSub.node_name(Loteria.PubSub)

# See who's subscribed to a game topic
Registry.lookup(Loteria.PubSub, "game:ABC-123")
```

## Inject Events using built-in PubSub

```elixir
# Broadcast a card drawn event to all players
Phoenix.PubSub.broadcast(Loteria.PubSub, "game:ABC-123", {:card_drawn, %{card_id: 1, card: %{id: 1, name: "El Gallo", emoji: "🐓"}}})

# Announce a fake winner
Phoenix.PubSub.broadcast(Loteria.PubSub, "game:ABC-123", {:winner, %{player_id: "fake", name: "Demo Player", winning_cards: [1, 2, 3, 4]}})

# Reset notification
Phoenix.PubSub.broadcast(Loteria.PubSub, "game:ABC-123", {:game_reset, %{}})
```

## Fault Tolerance Demo

```elixir
# Get a game pid
{:ok, pid} = Loteria.GameRegistry.find_game("RUA-517")

# Kill the process to show fault tolerance
Process.exit(pid, :kill)

# Show that other games are unaffected
Loteria.GameRegistry.list_games()

# Note: The killed game won't restart automatically (DynamicSupervisor with :temporary children)
# but other games continue working - isolation demo!
```

## Supervisor Tree

```elixir
# See top-level children
Supervisor.which_children(Loteria.Supervisor)

# See game supervisor children (active game processes)
Supervisor.which_children(Loteria.GameRegistry.Supervisor)

# Count game processes
Supervisor.count_children(Loteria.GameRegistry.Supervisor)
```
