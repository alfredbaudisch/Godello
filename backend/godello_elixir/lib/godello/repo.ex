defmodule Godello.Repo do
  use Ecto.Repo,
    otp_app: :godello,
    adapter: Ecto.Adapters.Postgres

  defimpl Jason.Encoder, for: Ecto.Association.NotLoaded do
    def encode(struct, _opts) do
      case struct.__cardinality__ do
        :many -> "[]"
        _ -> "{}"
      end
    end
  end
end
