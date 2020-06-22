defmodule GodelloWeb.UserChannelTest do
  use GodelloWeb.ChannelCase

  @moduletag :user_channel
  @moduletag :channels

  setup do
    user = user_fixture()

    {:ok, _, socket} =
      GodelloWeb.UserSocket
      |> socket("user", %{user: user})
      |> subscribe_and_join(GodelloWeb.UserChannel, "user:#{user.id}")

    %{socket: socket, user: user}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping")
    assert_reply ref, :ok, %{"pong" => true}
  end

  describe "create board" do
    test "with invalid params", %{socket: socket} do
      ref = push(socket, "create_board", %{})
      assert_reply ref, :error, payload
      assert contains_changeset_error?(payload, :name, "can't be blank")
    end

    test "with valid params", %{socket: socket, user: user} do
      create_and_validate_board(socket, user)
    end
  end

  test "get boards", %{socket: socket, user: user} do
    create_and_validate_board(socket, user)
    ref = push(socket, "get_boards")
    assert_reply ref, :ok, payload
    json = json_response(payload)
    assert Enum.count(json["boards"]) == 1
    validate_single_board(Enum.at(json["boards"], 0), user)

    create_and_validate_board(socket, user, "Second Project")
    ref = push(socket, "get_boards")
    assert_reply ref, :ok, payload
    json = json_response(payload)
    assert Enum.count(json["boards"]) == 2
    assert Enum.count(Enum.at(json["boards"], 0)["users"]) == 1
  end

  defp create_and_validate_board(socket, user, name \\ "Project Board") do
    ref = push(socket, "create_board", %{"name" => name})
    assert_reply ref, :ok, payload
    validate_single_board(json_response(payload), user, name)
    payload
  end

  defp validate_single_board(%{"id" => _} = board, user, board_name \\ "Project Board") do
    assert board["name"] == board_name
    assert board["owner_user_id"] == user.id
    [board_user_entry] = board["users"]
    assert Enum.count(board["users"]) == 1
    assert board_user_entry["is_owner"]
    assert board_user_entry["user"]["id"] == user.id
  end
end
