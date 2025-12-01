defmodule Loteria.Repo do
  use Ecto.Repo,
    otp_app: :loteria,
    adapter: Ecto.Adapters.Postgres
end
