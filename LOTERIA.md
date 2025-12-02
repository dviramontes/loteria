# Project: Loteria.live

A real-time multiplayer Lotería game built with Phoenix LiveView and PubSub.

## Tech Stack

- Phoenix LiveView for real-time UI
- PubSub for game state broadcasting
- No database required (in-memory game state via GenServer or Agent)

## Design Inspiration

- Visual style: [Google Doodle - Celebrating Lotería](https://doodles.google/doodle/celebrating-loteria/)
- Color palette: vibrant Mexican folk art colors (hot pink, teal, yellow, red, deep blue)
- Cards represented with emojis + Spanish names
- Traditional papel picado aesthetic for borders/decorations

---

## Game Concepts

### Roles

| Role | Description |
|------|-------------|
| **Cantor** (Game Master) | Creates game, controls pace, draws cards |
| **Jugador** (Player) | Receives a tabla, marks cards, calls Lotería |

### Key Terms

- **Tabla** — A player's 4×4 board of 16 randomly selected cards
- **Baraja** — The deck of all 54 Lotería cards
- **Cantar** — The act of drawing and announcing a card
- **Dicho** — Traditional rhyme or riddle used to announce each card

---

## Game Flow

```
┌─────────────────────────────────────────────────────────┐
│  1. LOBBY                                               │
│     └─ Cantor creates game → gets shareable room code   │
│     └─ Players join via code → see waiting screen       │
│     └─ Cantor sees player list, waits for everyone      │
├─────────────────────────────────────────────────────────┤
│  2. GAME START                                          │
│     └─ Cantor clicks "Empezar"                          │
│     └─ Each player receives randomized 4×4 tabla        │
│     └─ Deck is shuffled server-side                     │
│     └─ Game status changes to :playing                  │
├─────────────────────────────────────────────────────────┤
│  3. PLAY LOOP                                           │
│     └─ Cantor clicks "Siguiente" to draw next card      │
│     └─ Card broadcasts to all players via PubSub        │
│     └─ Players tap matching card on their tabla         │
│     └─ Marked cards show visual indicator (frijol)      │
│     └─ Repeat until someone wins                        │
├─────────────────────────────────────────────────────────┤
│  4. WIN CONDITION                                       │
│     └─ Player completes a row (horizontal OR vertical)  │
│     └─ Player clicks "¡Lotería!" button                 │
│     └─ Server validates marked cards against drawn list │
│     └─ If valid → broadcast winner, game ends           │
│     └─ If invalid → player notified, game continues     │
├─────────────────────────────────────────────────────────┤
│  5. GAME END                                            │
│     └─ Winner announced to all players                  │
│     └─ Confetti animation / celebration                 │
│     └─ Cantor can start new round (same room)           │
│     └─ Option to reshuffle tablas or keep them          │
└─────────────────────────────────────────────────────────┘
```

---

## Screen Specifications

### Cantor View

```
┌────────────────────────────────────────────────────────┐
│  LOTERIA.LIVE                        Players: 4 👥     │
├────────────────────────────────────────────────────────┤
│                                                        │
│              ┌─────────────────────┐                   │
│              │                     │                   │
│              │        🐓           │                   │
│              │                     │                   │
│              │     EL GALLO        │                   │
│              │                     │                   │
│              └─────────────────────┘                   │
│                                                        │
│    "El que le cantó a San Pedro"                       │
│                                                        │
│              [ ◀ SIGUIENTE ▶ ]                         │
│                                                        │
├────────────────────────────────────────────────────────┤
│  Historial:  😈 🌙 ⭐ 🦜 💀 🌳 ...                      │
└────────────────────────────────────────────────────────┘
```

**Elements:**
- Current card: large emoji + Spanish name + traditional dicho
- "Siguiente" button to draw next card
- History bar: horizontally scrolling list of drawn cards
- Player count indicator
- "Empezar" button (lobby phase only)
- Room code display for sharing

### Player View

```
┌────────────────────────────────────────────────────────┐
│  LOTERIA.LIVE           Actual: 🐓 El Gallo            │
├────────────────────────────────────────────────────────┤
│                                                        │
│    ┌──────┬──────┬──────┬──────┐                       │
│    │  🐓  │  🌙  │  💀  │  🎸  │                       │
│    │  ●   │      │      │      │                       │
│    ├──────┼──────┼──────┼──────┤                       │
│    │  🧜‍♀️  │  ⭐  │  🦂  │  🌵  │                       │
│    │      │      │      │      │                       │
│    ├──────┼──────┼──────┼──────┤                       │
│    │  🎩  │  🍉  │  🦜  │  🫀  │                       │
│    │      │      │      │      │                       │
│    ├──────┼──────┼──────┼──────┤                       │
│    │  ☂️  │  🌳  │  🔔  │  😈  │                       │
│    │      │      │      │      │                       │
│    └──────┴──────┴──────┴──────┘                       │
│                                                        │
│              [ ¡LOTERÍA! 🎉 ]                          │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**Elements:**
- 4×4 grid tabla with tappable emoji cards
- Current called card displayed at top
- Tap to mark → shows frijol (●) or bean overlay
- Tap again to unmark (in case of mistakes)
- "¡Lotería!" button (always visible, validated server-side)
- Subtle indicator when a row/column is complete

### Lobby View

```
┌────────────────────────────────────────────────────────┐
│                     LOTERIA.LIVE                       │
├────────────────────────────────────────────────────────┤
│                                                        │
│                    Código de Sala                      │
│                                                        │
│                  ┌─────────────────┐                   │
│                  │    ABC-123      │                   │
│                  └─────────────────┘                   │
│                      [ Copiar ]                        │
│                                                        │
│    ─────────────────────────────────────────────       │
│                                                        │
│    Jugadores:                                          │
│      • María ✓                                         │
│      • José ✓                                          │
│      • Esperando más jugadores...                      │
│                                                        │
│              [ EMPEZAR JUEGO ]  (cantor only)          │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## Complete Card Deck (La Baraja)

All 54 traditional Lotería cards with emoji mappings and traditional dichos:

```elixir
defmodule LoteriaLive.Cards do
  @moduledoc """
  The complete deck of 54 traditional Lotería cards.
  Each card has an id, Spanish name, emoji, and traditional dicho (riddle/rhyme).
  """

  @loteria_cards [
    %{id: 1, name: "El Gallo", emoji: "🐓", dicho: "El que le cantó a San Pedro"},
    %{id: 2, name: "El Diablito", emoji: "😈", dicho: "Pórtate bien, cuatito, si no te lleva el coloradito"},
    %{id: 3, name: "La Dama", emoji: "👩", dicho: "Échale un cinco a la dama"},
    %{id: 4, name: "El Catrín", emoji: "🎩", dicho: "Don Ferruco en la alameda, su bastón quería tirar"},
    %{id: 5, name: "El Paraguas", emoji: "☂️", dicho: "Para el sol y para el agua"},
    %{id: 6, name: "La Sirena", emoji: "🧜‍♀️", dicho: "Con los cantos de sirena, no te vayas a marear"},
    %{id: 7, name: "La Escalera", emoji: "🪜", dicho: "Súbeme paso a pasito, no quieras pegar brinquitos"},
    %{id: 8, name: "La Botella", emoji: "🍾", dicho: "La herramienta del borracho"},
    %{id: 9, name: "El Barril", emoji: "🛢️", dicho: "Tanto bebió el albañil, que quedó como barril"},
    %{id: 10, name: "El Árbol", emoji: "🌳", dicho: "El que a buen árbol se arrima, buena sombra le cobija"},
    %{id: 11, name: "El Melón", emoji: "🍈", dicho: "Me lo das o me lo quitas"},
    %{id: 12, name: "El Valiente", emoji: "🤠", dicho: "Por qué le corres cobarde, trayendo tan buen puñal"},
    %{id: 13, name: "El Gorrito", emoji: "🧢", dicho: "Ponle su gorrito al nene, no se nos vaya a resfriar"},
    %{id: 14, name: "La Muerte", emoji: "💀", dicho: "La muerte tilica y flaca"},
    %{id: 15, name: "La Pera", emoji: "🍐", dicho: "El que espera, desespera"},
    %{id: 16, name: "La Bandera", emoji: "🇲🇽", dicho: "Verde, blanco y colorado, la bandera del soldado"},
    %{id: 17, name: "El Bandolón", emoji: "🎸", dicho: "Tocando su bandolón, está el mariachi en la esquina"},
    %{id: 18, name: "El Violoncello", emoji: "🎻", dicho: "Creciendo se fue hasta el cielo, y como no fue violín, tuvo que ser violoncello"},
    %{id: 19, name: "La Garza", emoji: "🦢", dicho: "Al otro lado del río tengo mi banco de arena, donde se sienta mi chata pico de garza morena"},
    %{id: 20, name: "El Pájaro", emoji: "🐦", dicho: "Tú me traes a puros brincos, como pájaro en la rama"},
    %{id: 21, name: "La Mano", emoji: "🤚", dicho: "La mano de un criminal"},
    %{id: 22, name: "La Bota", emoji: "🥾", dicho: "Una bota igual que la otra"},
    %{id: 23, name: "La Luna", emoji: "🌙", dicho: "El farol de los enamorados"},
    %{id: 24, name: "El Cotorro", emoji: "🦜", dicho: "Cotorro cotorro saca la pata, y empiézame a platicar"},
    %{id: 25, name: "El Borracho", emoji: "🥴", dicho: "Ah qué borracho tan necio, ya no lo puedo aguantar"},
    %{id: 26, name: "El Negrito", emoji: "👤", dicho: "El que se comió el azúcar"},
    %{id: 27, name: "El Corazón", emoji: "🫀", dicho: "No me extrañes corazón, que regreso en el camión"},
    %{id: 28, name: "La Sandía", emoji: "🍉", dicho: "La barriga que Juan tenía, era empacho de sandía"},
    %{id: 29, name: "El Tambor", emoji: "🥁", dicho: "No te arrugues cuero viejo, que te quiero pa' tambor"},
    %{id: 30, name: "El Camarón", emoji: "🦐", dicho: "Camarón que se duerme, se lo lleva la corriente"},
    %{id: 31, name: "Las Jaras", emoji: "🎯", dicho: "Las jaras del indio Azteca"},
    %{id: 32, name: "El Músico", emoji: "🎺", dicho: "El músico trae su guitarra, para tocar bellas melodías"},
    %{id: 33, name: "La Araña", emoji: "🕷️", dicho: "Atarántamela a palos, no me la dejes llegar"},
    %{id: 34, name: "El Soldado", emoji: "💂", dicho: "Uno, dos, tres, el soldado pa' sus dieces"},
    %{id: 35, name: "La Estrella", emoji: "⭐", dicho: "La guía de los marineros"},
    %{id: 36, name: "El Cazo", emoji: "🥘", dicho: "El que nace pa' cazo, del cielo le caen las asas"},
    %{id: 37, name: "El Mundo", emoji: "🌍", dicho: "Este mundo es una bola, y nosotros un bolón"},
    %{id: 38, name: "El Apache", emoji: "🪶", dicho: "¡Ah, Chihuahua! Cuánto apache con pantalón y huarache"},
    %{id: 39, name: "El Nopal", emoji: "🌵", dicho: "Al nopal lo van a ver, nomás cuando tiene tunas"},
    %{id: 40, name: "El Alacrán", emoji: "🦂", dicho: "El que con la cola pica, le dan una paliza"},
    %{id: 41, name: "La Rosa", emoji: "🌹", dicho: "Rosita, Rosaura, ven que te quiero ahora"},
    %{id: 42, name: "La Calavera", emoji: "☠️", dicho: "Al pasar por el panteón, me encontré un calaverón"},
    %{id: 43, name: "La Campana", emoji: "🔔", dicho: "Tú con la campana y yo con tu hermana"},
    %{id: 44, name: "El Cantarito", emoji: "🏺", dicho: "Tanto va el cántaro al agua, que se quiebra y te moja las enaguas"},
    %{id: 45, name: "El Venado", emoji: "🦌", dicho: "Saltando va el venadito"},
    %{id: 46, name: "El Sol", emoji: "☀️", dicho: "La cobija de los pobres"},
    %{id: 47, name: "La Corona", emoji: "👑", dicho: "El sombrero de los reyes"},
    %{id: 48, name: "La Chalupa", emoji: "🛶", dicho: "Rema que rema Lupita, sentada en su chalupita"},
    %{id: 49, name: "El Pino", emoji: "🌲", dicho: "Fresco y oloroso, en todo tiempo hermoso"},
    %{id: 50, name: "El Pescado", emoji: "🐟", dicho: "El que por la boca muere"},
    %{id: 51, name: "La Palma", emoji: "🌴", dicho: "Palmero, sube a la palma y bájame un coco real"},
    %{id: 52, name: "La Maceta", emoji: "🪴", dicho: "El que nace pa' maceta, no pasa del corredor"},
    %{id: 53, name: "El Arpa", emoji: "🎵", dicho: "Arpa vieja de mi suegra, ya no sirves pa' tocar"},
    %{id: 54, name: "La Rana", emoji: "🐸", dicho: "Al ver a la verde rana, qué brinco pegó tu hermana"}
  ]

  def all_cards, do: @loteria_cards

  def get_card(id), do: Enum.find(@loteria_cards, &(&1.id == id))

  def random_tabla do
    @loteria_cards
    |> Enum.shuffle()
    |> Enum.take(16)
    |> Enum.map(& &1.id)
  end

  def shuffled_deck do
    @loteria_cards
    |> Enum.shuffle()
    |> Enum.map(& &1.id)
  end
end
```

---

## State Structure

```elixir
defmodule LoteriaLive.Game do
  @moduledoc """
  Game state structure and operations.
  """

  defstruct [
    :id,                    # "abc123" - room code
    :status,                # :lobby | :playing | :finished
    :cantor_id,             # socket id of the game master
    :players,               # %{player_id => %Player{}}
    :deck,                  # [card_ids] - remaining cards to draw
    :drawn,                 # [card_ids] - cards already called (in order)
    :current_card,          # card_id | nil
    :winner,                # player_id | nil
    :created_at             # DateTime
  ]

  defmodule Player do
    defstruct [
      :id,
      :name,
      :tabla,                # [16 card_ids] - the player's board
      :marked                # MapSet of card_ids the player has marked
    ]
  end
end
```

### Example State

```elixir
%Game{
  id: "ABC-123",
  status: :playing,
  cantor_id: "phx-F1234",
  players: %{
    "phx-F5678" => %Player{
      id: "phx-F5678",
      name: "María",
      tabla: [1, 6, 14, 17, 23, 27, 35, 39, 41, 43, 46, 48, 50, 52, 53, 54],
      marked: MapSet.new([1, 23, 35])
    },
    "phx-F9012" => %Player{
      id: "phx-F9012",
      name: "José",
      tabla: [2, 5, 8, 11, 15, 19, 22, 28, 31, 33, 36, 40, 44, 47, 49, 51],
      marked: MapSet.new([2, 11])
    }
  },
  deck: [3, 4, 7, 9, 10, 12, 13, 16, 18, 20, 21, 24, 25, 26, 29, 30, ...],
  drawn: [1, 2, 23, 35, 11],
  current_card: 11,
  winner: nil,
  created_at: ~U[2024-01-15 20:30:00Z]
}
```

---

## PubSub Events

| Topic | Event | Payload | Description |
|-------|-------|---------|-------------|
| `game:{id}` | `:player_joined` | `%{player_id, name}` | New player entered lobby |
| `game:{id}` | `:player_left` | `%{player_id}` | Player disconnected |
| `game:{id}` | `:game_started` | `%{tablas: %{player_id => tabla}}` | Game begun, tablas distributed |
| `game:{id}` | `:card_drawn` | `%{card_id, card}` | New card announced |
| `game:{id}` | `:loteria_claimed` | `%{player_id, name}` | Someone clicked ¡Lotería! |
| `game:{id}` | `:winner` | `%{player_id, name, winning_cards}` | Valid win confirmed |
| `game:{id}` | `:invalid_claim` | `%{player_id}` | Claim rejected |
| `game:{id}` | `:game_reset` | `%{}` | New round starting |

---

## Module Structure

```
lib/
├── loteria_live/
│   ├── application.ex
│   ├── cards.ex                 # Card definitions and helpers
│   ├── game.ex                  # Game struct and logic
│   ├── game_server.ex           # GenServer for game state
│   └── game_registry.ex         # Registry for active games
│
├── loteria_live_web/
│   ├── components/
│   │   ├── card_component.ex    # Single Lotería card
│   │   ├── tabla_component.ex   # 4x4 player board
│   │   └── history_component.ex # Drawn cards history
│   │
│   ├── live/
│   │   ├── home_live.ex         # Landing page, create/join
│   │   ├── game_live.ex         # Main game (routes to cantor/player)
│   │   ├── cantor_live.ex       # Game master view
│   │   └── player_live.ex       # Player view
│   │
│   └── router.ex
│
assets/
├── css/
│   └── loteria.css              # Custom styles, papel picado, etc.
└── js/
    └── hooks/                   # Any JS hooks (confetti, sounds)
```

---

## Routes

```elixir
scope "/", LoteriaLiveWeb do
  pipe_through :browser

  live "/", HomeLive, :index
  live "/game/:id", GameLive, :show
  live "/game/:id/cantor", CantorLive, :show
  live "/game/:id/play", PlayerLive, :show
end
```

---

## Win Validation Logic

```elixir
defmodule LoteriaLive.Game do
  @doc """
  Check if a player has a valid winning line.
  Returns {:ok, winning_cards} or :no_win
  """
  def check_win(%Player{tabla: tabla, marked: marked}, drawn) do
    # Tabla is a flat list of 16 card_ids, representing 4x4 grid
    # Index mapping:
    #  0  1  2  3
    #  4  5  6  7
    #  8  9 10 11
    # 12 13 14 15

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

    # Optional: include diagonals
    # diagonals = [[0, 5, 10, 15], [3, 6, 9, 12]]

    lines = rows ++ cols

    drawn_set = MapSet.new(drawn)

    winning_line =
      Enum.find(lines, fn indices ->
        cards = Enum.map(indices, &Enum.at(tabla, &1))
        
        # All cards in line must be:
        # 1. Marked by the player
        # 2. Actually drawn by the cantor
        Enum.all?(cards, fn card_id ->
          MapSet.member?(marked, card_id) and MapSet.member?(drawn_set, card_id)
        end)
      end)

    case winning_line do
      nil -> :no_win
      indices -> {:ok, Enum.map(indices, &Enum.at(tabla, &1))}
    end
  end
end
```

---

## Configuration Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Diagonal wins | ❌ No (initially) | Keep it simple for v1, can add later |
| Auto-advance | ❌ Manual only | Preserves traditional cantor role |
| Spectator mode | ❌ No (initially) | Adds complexity, defer to v2 |
| Player names | ✅ Required | Better UX for announcements |
| Rematch tablas | ✅ Reshuffle | More variety, traditional behavior |
| Min players | 2 | At least cantor + 1 player |
| Max players | 20 | Reasonable limit for PubSub |

---

## Future Enhancements (v2+)

- [ ] Sound effects for card announcements (Text-to-speech dichos)
- [ ] Diagonal win condition toggle
- [ ] Auto-advance mode with configurable timing (3s, 5s, 10s)
- [ ] Spectator mode
- [ ] Multiple win conditions (4 corners, full card, etc.)
- [ ] Persistent game history / leaderboards
- [ ] Custom card deck builder
- [ ] Mobile app wrapper (LiveView Native)
- [ ] Accessibility improvements (screen reader support)
- [ ] Internationalization (English card names option)

---

## Development Checklist

### Phase 1: Foundation
- [ ] Phoenix project setup with LiveView
- [ ] Cards module with all 54 cards
- [ ] Basic routing structure
- [ ] Home page with create/join game

### Phase 2: Game Logic
- [ ] GameServer GenServer
- [ ] Game state management
- [ ] PubSub setup and events
- [ ] Player join/leave handling

### Phase 3: UI
- [ ] Cantor view with card display
- [ ] Player view with interactive tabla
- [ ] Lobby waiting room
- [ ] Win announcement screen

### Phase 4: Polish
- [ ] Visual styling (Google Doodle inspired)
- [ ] Animations (card flip, marking, confetti)
- [ ] Error handling and edge cases
- [ ] Mobile responsiveness

### Phase 5: Deploy
- [ ] Production configuration
- [ ] Deployment (Fly.io / Render / Gigalixir)
- [ ] Domain setup (loteria.live)
