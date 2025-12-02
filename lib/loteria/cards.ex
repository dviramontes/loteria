defmodule Loteria.Cards do
  @moduledoc """
  The complete deck of 54 traditional Lotería cards.
  Each card has an id, Spanish name, emoji, and traditional dicho (riddle/rhyme).
  """

  @loteria_cards [
    %{id: 1, name: "El Gallo", emoji: "🐓", dicho: "El que le cantó a San Pedro"},
    %{
      id: 2,
      name: "El Diablito",
      emoji: "😈",
      dicho: "Pórtate bien, cuatito, si no te lleva el coloradito"
    },
    %{id: 3, name: "La Dama", emoji: "👩", dicho: "Échale un cinco a la dama"},
    %{
      id: 4,
      name: "El Catrín",
      emoji: "🎩",
      dicho: "Don Ferruco en la alameda, su bastón quería tirar"
    },
    %{id: 5, name: "El Paraguas", emoji: "☂️", dicho: "Para el sol y para el agua"},
    %{
      id: 6,
      name: "La Sirena",
      emoji: "🧜‍♀️",
      dicho: "Con los cantos de sirena, no te vayas a marear"
    },
    %{
      id: 7,
      name: "La Escalera",
      emoji: "🪜",
      dicho: "Súbeme paso a pasito, no quieras pegar brinquitos"
    },
    %{id: 8, name: "La Botella", emoji: "🍾", dicho: "La herramienta del borracho"},
    %{
      id: 9,
      name: "El Barril",
      emoji: "🛢️",
      dicho: "Tanto bebió el albañil, que quedó como barril"
    },
    %{
      id: 10,
      name: "El Árbol",
      emoji: "🌳",
      dicho: "El que a buen árbol se arrima, buena sombra le cobija"
    },
    %{id: 11, name: "El Melón", emoji: "🍈", dicho: "Me lo das o me lo quitas"},
    %{
      id: 12,
      name: "El Valiente",
      emoji: "🤠",
      dicho: "Por qué le corres cobarde, trayendo tan buen puñal"
    },
    %{
      id: 13,
      name: "El Gorrito",
      emoji: "🧢",
      dicho: "Ponle su gorrito al nene, no se nos vaya a resfriar"
    },
    %{id: 14, name: "La Muerte", emoji: "💀", dicho: "La muerte tilica y flaca"},
    %{id: 15, name: "La Pera", emoji: "🍐", dicho: "El que espera, desespera"},
    %{
      id: 16,
      name: "La Bandera",
      emoji: "🇲🇽",
      dicho: "Verde, blanco y colorado, la bandera del soldado"
    },
    %{
      id: 17,
      name: "El Bandolón",
      emoji: "🎸",
      dicho: "Tocando su bandolón, está el mariachi en la esquina"
    },
    %{
      id: 18,
      name: "El Violoncello",
      emoji: "🎻",
      dicho: "Creciendo se fue hasta el cielo, y como no fue violín, tuvo que ser violoncello"
    },
    %{
      id: 19,
      name: "La Garza",
      emoji: "🦢",
      dicho:
        "Al otro lado del río tengo mi banco de arena, donde se sienta mi chata pico de garza morena"
    },
    %{
      id: 20,
      name: "El Pájaro",
      emoji: "🐦",
      dicho: "Tú me traes a puros brincos, como pájaro en la rama"
    },
    %{id: 21, name: "La Mano", emoji: "🤚", dicho: "La mano de un criminal"},
    %{id: 22, name: "La Bota", emoji: "🥾", dicho: "Una bota igual que la otra"},
    %{id: 23, name: "La Luna", emoji: "🌙", dicho: "El farol de los enamorados"},
    %{
      id: 24,
      name: "El Cotorro",
      emoji: "🦜",
      dicho: "Cotorro cotorro saca la pata, y empiézame a platicar"
    },
    %{
      id: 25,
      name: "El Borracho",
      emoji: "🥴",
      dicho: "Ah qué borracho tan necio, ya no lo puedo aguantar"
    },
    %{id: 26, name: "El Negrito", emoji: "👤", dicho: "El que se comió el azúcar"},
    %{
      id: 27,
      name: "El Corazón",
      emoji: "🫀",
      dicho: "No me extrañes corazón, que regreso en el camión"
    },
    %{
      id: 28,
      name: "La Sandía",
      emoji: "🍉",
      dicho: "La barriga que Juan tenía, era empacho de sandía"
    },
    %{
      id: 29,
      name: "El Tambor",
      emoji: "🥁",
      dicho: "No te arrugues cuero viejo, que te quiero pa' tambor"
    },
    %{
      id: 30,
      name: "El Camarón",
      emoji: "🦐",
      dicho: "Camarón que se duerme, se lo lleva la corriente"
    },
    %{id: 31, name: "Las Jaras", emoji: "🎯", dicho: "Las jaras del indio Azteca"},
    %{
      id: 32,
      name: "El Músico",
      emoji: "🎺",
      dicho: "El músico trae su guitarra, para tocar bellas melodías"
    },
    %{id: 33, name: "La Araña", emoji: "🕷️", dicho: "Atarántamela a palos, no me la dejes llegar"},
    %{id: 34, name: "El Soldado", emoji: "💂", dicho: "Uno, dos, tres, el soldado pa' sus dieces"},
    %{id: 35, name: "La Estrella", emoji: "⭐", dicho: "La guía de los marineros"},
    %{
      id: 36,
      name: "El Cazo",
      emoji: "🥘",
      dicho: "El que nace pa' cazo, del cielo le caen las asas"
    },
    %{id: 37, name: "El Mundo", emoji: "🌍", dicho: "Este mundo es una bola, y nosotros un bolón"},
    %{
      id: 38,
      name: "El Apache",
      emoji: "🪶",
      dicho: "¡Ah, Chihuahua! Cuánto apache con pantalón y huarache"
    },
    %{
      id: 39,
      name: "El Nopal",
      emoji: "🌵",
      dicho: "Al nopal lo van a ver, nomás cuando tiene tunas"
    },
    %{
      id: 40,
      name: "El Alacrán",
      emoji: "🦂",
      dicho: "El que con la cola pica, le dan una paliza"
    },
    %{id: 41, name: "La Rosa", emoji: "🌹", dicho: "Rosita, Rosaura, ven que te quiero ahora"},
    %{
      id: 42,
      name: "La Calavera",
      emoji: "☠️",
      dicho: "Al pasar por el panteón, me encontré un calaverón"
    },
    %{id: 43, name: "La Campana", emoji: "🔔", dicho: "Tú con la campana y yo con tu hermana"},
    %{
      id: 44,
      name: "El Cantarito",
      emoji: "🏺",
      dicho: "Tanto va el cántaro al agua, que se quiebra y te moja las enaguas"
    },
    %{id: 45, name: "El Venado", emoji: "🦌", dicho: "Saltando va el venadito"},
    %{id: 46, name: "El Sol", emoji: "☀️", dicho: "La cobija de los pobres"},
    %{id: 47, name: "La Corona", emoji: "👑", dicho: "El sombrero de los reyes"},
    %{
      id: 48,
      name: "La Chalupa",
      emoji: "🛶",
      dicho: "Rema que rema Lupita, sentada en su chalupita"
    },
    %{id: 49, name: "El Pino", emoji: "🌲", dicho: "Fresco y oloroso, en todo tiempo hermoso"},
    %{id: 50, name: "El Pescado", emoji: "🐟", dicho: "El que por la boca muere"},
    %{
      id: 51,
      name: "La Palma",
      emoji: "🌴",
      dicho: "Palmero, sube a la palma y bájame un coco real"
    },
    %{
      id: 52,
      name: "La Maceta",
      emoji: "🪴",
      dicho: "El que nace pa' maceta, no pasa del corredor"
    },
    %{
      id: 53,
      name: "El Arpa",
      emoji: "🎵",
      dicho: "Arpa vieja de mi suegra, ya no sirves pa' tocar"
    },
    %{
      id: 54,
      name: "La Rana",
      emoji: "🐸",
      dicho: "Al ver a la verde rana, qué brinco pegó tu hermana"
    }
  ]

  @doc """
  Returns all 54 Lotería cards.
  """
  def all_cards, do: @loteria_cards

  @doc """
  Gets a card by its ID.
  """
  def get_card(id) when is_integer(id) do
    Enum.find(@loteria_cards, &(&1.id == id))
  end

  def get_card(_), do: nil

  @doc """
  Generates a random 4x4 tabla (16 cards) for a player.
  Returns a list of 16 card IDs.
  """
  def random_tabla do
    @loteria_cards
    |> Enum.shuffle()
    |> Enum.take(16)
    |> Enum.map(& &1.id)
  end

  @doc """
  Returns a shuffled deck of all card IDs for the cantor to draw from.
  """
  def shuffled_deck do
    @loteria_cards
    |> Enum.shuffle()
    |> Enum.map(& &1.id)
  end

  @doc """
  Returns the total number of cards in the deck.
  """
  def deck_size, do: length(@loteria_cards)
end
