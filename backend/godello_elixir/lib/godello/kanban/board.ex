defmodule Godello.Kanban.Board do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :owner_user_id, :users, :inserted_at, :updated_at]}
  schema "boards" do
    field :name, :string
    belongs_to(:owner_user, Godello.Accounts.User)

    many_to_many(:users, Godello.Accounts.User,
      join_through: Godello.Kanban.BoardUser,
      on_replace: :delete,
      on_delete: :delete_all
    )

    timestamps()
  end

  @doc false
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:name, :owner_user_id])
    |> validate_required([:name, :owner_user_id])
  end
end
