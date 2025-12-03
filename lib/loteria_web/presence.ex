defmodule LoteriaWeb.Presence do
  @moduledoc """
  Presence tracking for Lotería game rooms.
  Tracks which players are currently connected to each game.
  """

  use Phoenix.Presence,
    otp_app: :loteria,
    pubsub_server: Loteria.PubSub
end
