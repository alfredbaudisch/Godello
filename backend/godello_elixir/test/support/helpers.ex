defmodule GodelloWeb.TestHelpers do
  alias Godello.{Accounts, Kanban}

  @valid_user %{
    first_name: "Koda",
    last_name: "Dachshund",
    email: "koda@thedachshund.com",
    password: "abc123",
    password_confirmation: "abc123"
  }

  @valid_board %{
    name: "Project Board"
  }

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@valid_user)
      |> Accounts.create_user()

    user
  end

  def board_fixture(user, attrs \\ %{}) do
    {:ok, board} =
      attrs
      |> Enum.into(@valid_board)
      |> Kanban.create_board(user)

    board
  end

  def board_member_fixture(board, user) do
  end

  def create_user_and_board do
    user = user_fixture()
    %{user: user, board: board_fixture(user)}
  end
end
