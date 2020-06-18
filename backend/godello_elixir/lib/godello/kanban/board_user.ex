defmodule Godello.Kanban.BoardUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "board_users" do
    belongs_to(:board, Godello.Kanban.Board)
    belongs_to(:user, Godello.Accounts.User)
    timestamps()
  end

  def changeset(board_user, attrs) do
    board_user
    |> cast(attrs, [:board_id, :user_id])
    |> validate_required([:board_id, :user_id])
  end
end
