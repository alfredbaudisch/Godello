defmodule GodelloWeb.BoardChannelTest do
  use GodelloWeb.ChannelCase

  @moduletag :board_channel
  @moduletag :channels

  setup do
    {:ok, _, socket} =
      GodelloWeb.UserSocket
      |> socket("user", %{user: %{id: 1}})
      |> subscribe_and_join(GodelloWeb.BoardChannel, "board:1")

    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end
end
