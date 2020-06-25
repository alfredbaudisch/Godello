defmodule GodelloWeb.BoardChannelTest do
  use GodelloWeb.ChannelCase

  @moduletag :board_channel
  @moduletag :channels

  setup do
    (%{user: user, board: board} = fixtures) = create_user_and_board()
    {:ok, join_data, socket} = join_board_channel(user, board)
    %{socket: socket, join_data: join_data} |> Map.merge(fixtures)
  end

  test "get board when joining channel", %{join_data: %{board: board_joined}, board: board} do
    assert board_joined.id == board.id
    assert is_list(board_joined.lists)
    assert is_list(board_joined.users)
  end

  test "can't join nonexistent board", %{user: user} do
    {:error, %{details: "The board doesn't exist", reason: "join_error"}} =
      join_board_channel(user, %Board{id: -1})
  end

  test "get board again", %{socket: socket} do
    ref = push(socket, "get_board")
    assert_reply ref, :ok, board
    assert is_list(board.lists)
    assert is_list(board.users)
  end

  test "delete board", %{socket: socket} do
    ref = push(socket, "delete_board")
    assert_reply ref, :ok, _board

    ref = push(socket, "delete_board")
    assert_reply ref, :error, error
    assert error.errors.reason == "board_not_found"
  end

  @tag :update_board
  test "update board", %{socket: socket} do
    ref = push(socket, "update_board", %{"name" => ""})
    assert_reply ref, :error, errors
    assert contains_changeset_error?(errors, :name, "can't be blank")

    ref = push(socket, "update_board", %{"name" => "New Name"})
    assert_reply ref, :ok, board_updated
    assert board_updated.name == "New Name"

    assert_broadcast "board_updated", board_updated_broadcasted
    assert board_updated_broadcasted.name == "New Name"
  end

  describe "membership" do
    test "non-member can't join board", %{board: board} do
      another_user = user_fixture(%{email: "another@user.com"})

      {:error, %{details: "You can't join this board", reason: "join_unauthorized"}} =
        join_board_channel(another_user, board)
    end

    test "added member can join board", %{socket: socket} do
      another_user = user_fixture(%{email: "another@user.com"})

      ref = push(socket, "add_member", %{"email" => another_user.email})
      assert_reply ref, :ok, board
      assert Enum.count(board.users) == 2

      assert_broadcast "board_updated", board_updated
      assert Enum.count(board.users) == 2
      assert board_updated.id == board.id

      {:ok, %{board: board_joined}, _another_socket} = join_board_channel(another_user, board)
      assert board_joined.id == board.id
    end

    test "nonexistent user can't be added", %{socket: socket} do
      ref = push(socket, "add_member", %{"email" => "another@user.com"})
      assert_reply ref, :error, error
      assert error.errors.reason == "user_not_found"
    end

    test "can't add the same user twice", %{socket: socket, user: user} do
      ref = push(socket, "add_member", %{"email" => user.email})
      assert_reply ref, :error, error
      assert contains_changeset_error?(error, :board_id, "has already been taken")

      another_user = user_fixture(%{email: "another@user.com"})
      ref = push(socket, "add_member", %{"email" => another_user.email})
      assert_reply ref, :ok, _board

      ref = push(socket, "add_member", %{"email" => another_user.email})
      assert_reply ref, :error, error
      assert contains_changeset_error?(error, :board_id, "has already been taken")
    end

    test "can remove added member", %{socket: socket} do
      another_user = user_fixture(%{email: "another@user.com"})
      ref = push(socket, "add_member", %{"email" => another_user.email})
      assert_reply ref, :ok, board
      assert_broadcast "board_updated", _board_updated

      ref = push(socket, "remove_member", %{"user_id" => another_user.id})
      assert_reply ref, :ok, board
      assert Enum.count(board.users) == 1
      assert_broadcast "board_updated", board_updated
      assert Enum.count(board_updated.users) == 1
    end

    test "can't remove nonexistent member", %{socket: socket} do
      another_user = user_fixture(%{email: "another@user.com"})

      ref = push(socket, "remove_member", %{"user_id" => another_user.id})
      assert_reply ref, :error, error
      assert error.errors.reason == "user_not_found"
    end

    test "can't remove owner", %{socket: socket, user: user} do
      ref = push(socket, "remove_member", %{"user_id" => user.id})
      assert_reply ref, :error, error
      assert error.errors.reason == "user_is_owner"
    end
  end

  defp join_board_channel(user, %Board{id: board_id}) do
    GodelloWeb.UserSocket
    |> socket("user", %{user: user})
    |> subscribe_and_join(GodelloWeb.BoardChannel, "board:#{board_id}")
  end
end
