defmodule Godello.Kanban.Board do
  use Ecto.Schema
  import Ecto.Changeset

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
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
