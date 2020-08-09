defmodule Godello.Kanban.BoardUser do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :is_owner, :user, :board_id]}
  schema "board_users" do
    field :is_owner, :boolean, default: false
    belongs_to(:board, Godello.Kanban.Board)
    belongs_to(:user, Godello.Accounts.User)
    timestamps()
  end

  def changeset(board_user, attrs) do
    board_user
    |> cast(attrs, [:is_owner, :board_id, :user_id])
    |> validate_required([:board_id, :user_id])
    |> unique_constraint([:board_id, :user_id], message: "already has this user as a member")
  end
end
