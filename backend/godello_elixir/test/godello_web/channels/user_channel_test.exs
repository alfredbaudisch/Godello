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
      ref = push(socket, "create_board", %{"name" => "Project Board"})
      assert_reply ref, :ok, payload
      assert_key(payload, "name", "Project Board")
      assert_key(payload, "owner_user_id", user.id)
    end
  end
end
