defmodule GodelloWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](http://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :godello,
    pubsub_server: Godello.PubSub

  @board_channel "board:"

  def start_tracking(socket) do
    track(socket, socket.assigns.user.id |> to_string(), %{
      online_at: System.system_time(:second)
    })
  end

  def list_for_board(board_id) do
    list("#{@board_channel}#{board_id}")
  end
end
