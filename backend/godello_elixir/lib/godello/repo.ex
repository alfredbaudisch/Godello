defmodule Godello.Repo do
  use Ecto.Repo,
    otp_app: :godello,
    adapter: Ecto.Adapters.Postgres
end
