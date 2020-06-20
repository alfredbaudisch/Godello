defmodule GodelloWeb.BoardChannelTest do
  use GodelloWeb.ChannelCase

  @moduletag :board_channel
  @moduletag :channels

  setup do
    (%{user: user, board: board} = fixtures) = create_user_and_board()
    {:ok, _, socket} = join_board_channel(user, board)
    %{socket: socket} |> Map.merge(fixtures)
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "non-member can't join board", %{board: board} do
    another_user = user_fixture(%{email: "another@user.com"})

    {:error, %{details: "You can't join this board", reason: "join_unauthorized"}} =
      join_board_channel(another_user, board)
  end

  test "add member and then added member can join board", %{socket: socket, board: board} do
    another_user = user_fixture(%{email: "another@user.com"})
    push(socket, "add_member", %{"email" => another_user.email})
    assert_broadcast "member_added", %{"email" => email_added}
    assert email_added == another_user.email

    {:ok, _, another_socket} = join_board_channel(another_user, board)
  end

  defp join_board_channel(user, %Board{id: board_id}) do
    GodelloWeb.UserSocket
    |> socket("user", %{user: user})
    |> subscribe_and_join(GodelloWeb.BoardChannel, "board:#{board_id}")
  end
end
