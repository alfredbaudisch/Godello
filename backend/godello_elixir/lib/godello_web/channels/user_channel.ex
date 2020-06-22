defmodule GodelloWeb.UserChannel do
  use GodelloWeb, :channel
  @user_channel "user:"

  alias Godello.{Accounts, Kanban}

  #
  # JOIN
  #

  @impl true
  def join(@user_channel <> _id, _params, %{assigns: %{user: nil}} = _socket) do
    not_authenticated()
  end

  def join(@user_channel <> _id, _params, %{assigns: %{user: %{id: user_id}}} = _socket)
      when is_nil(user_id) do
    not_authenticated()
  end

  def join(
        @user_channel <> join_user_id,
        _params,
        %{assigns: %{user: %{id: user_id}}} = socket
      ) do
    try do
      join_user_id = join_user_id |> String.to_integer()

      if join_user_id == user_id do
        # Uniquely identify the channel connection
        conn_id = Ecto.UUID.generate()

        socket =
          socket
          |> assign(:conn_id, conn_id)

        send(self(), :after_join)
        {:ok, %{conn_id: conn_id}, socket}
      else
        error("join_unauthorized", "Only the user can join its own board")
      end
    rescue
      _e in ArgumentError ->
        error("join_error", "user_id must be a number")
    end
  end

  def join(_, _, _) do
    error("join_error", "Invalid topic or user not provided")
  end

  @impl true
  def handle_info(:after_join, socket) do
    # Track the user being online
    {:ok, _} = Presence.start_tracking(socket)
    {:noreply, socket}
  end

  #
  # EVENT DEFINITIONS
  #

  # In
  @ping "ping"
  @create_board "create_board"
  @get_boards "get_boards"

  #
  # EVENTS IN
  #

  @impl true
  def handle_in(@ping, _params, socket) do
    {:reply, {:ok, %{"pong" => true}}, socket}
  end

  def handle_in(@create_board, params, %{assigns: %{user: %{id: user_id}}} = socket) do
    Kanban.create_board(params, user_id)
    |> json_response(socket)
  end
end
