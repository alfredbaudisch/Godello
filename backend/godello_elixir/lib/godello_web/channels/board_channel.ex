defmodule GodelloWeb.BoardChannel do
  use GodelloWeb, :channel
  @board_channel "board:"

  alias Godello.Kanban
  alias Godello.Kanban.{Board}
  alias GodelloWeb.GenericError

  @impl true
  def join(@board_channel <> _id, _params, %{assigns: %{user: nil}} = _socket) do
    not_authenticated()
  end

  def join(@board_channel <> _id, _params, %{assigns: %{user: %{id: user_id}}} = _socket)
      when is_nil(user_id) do
    not_authenticated()
  end

  def join(
        @board_channel <> join_board_id,
        _params,
        %{assigns: %{user: %{id: user_id}}} = socket
      ) do
    try do
      join_board_id = join_board_id |> String.to_integer()

      Kanban.get_board(join_board_id)
      |> case do
        %Board{} = board ->
          if Kanban.user_has_permission_to_board?(user_id, board) do
            conn_id = Ecto.UUID.generate()

            socket =
              socket
              |> assign(:conn_id, conn_id)
              |> assign(:board_id, board.id)

            send(self(), :after_join)
            {:ok, render_response_value(%{conn_id: conn_id, board: board}), socket}
          else
            error("join_unauthorized", "You can't join this board")
          end

        nil ->
          error("join_error", "The board doesn't exist")
      end
    rescue
      _e in ArgumentError ->
        error("join_error", "board_id must be a number")
    end
  end

  def join(_, _, _) do
    error("join_error", "Invalid topic or board not provided")
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
  @get_board "get_board"
  @add_member "add_member"
  @remove_member "remove_member"

  # Out
  @board_updated "board_updated"
  @board_membership_removed "board_membership_removed"

  #
  # EVENTS IN
  #

  @impl true
  def handle_in(@add_member, %{"email" => email}, %{assigns: %{board_id: board_id}} = socket) do
    with {:ok, _board_user} <- Kanban.add_board_user(board_id, email) do
      board = get_board_info(socket)
      broadcast_board_updated(socket, board)
      board
    else
      {:error, :user_not_found} ->
        {:error, GenericError.new("user_not_found", "No User found with that email")}

      error ->
        error
    end
    |> json_response(socket)
  end

  def handle_in(
        @remove_member,
        %{"user_id" => user_id},
        %{assigns: %{board_id: board_id}} = socket
      ) do
    with {:ok, deleted_board_user} <- Kanban.remove_board_user(board_id, user_id) do
      board = get_board_info(socket)
      broadcast_board_updated_all_members(socket, board)
      broadcast_user_channel(deleted_board_user.user_id, @board_membership_removed, board)
      board
    else
      {:error, :user_not_found} ->
        {:error, GenericError.new("user_not_found", "User is not a member of the Board")}

      {:error, :user_is_owner} ->
        {:error,
         GenericError.new(
           "user_is_owner",
           "This User is the owner of the Board and can't be removed"
         )}

      error ->
        error
    end
    |> json_response(socket)
  end

  #
  # HELPERS
  #

  defp get_board_info(%{assigns: %{board_id: board_id}}) do
    Kanban.get_board_info(board_id)
  end

  @doc """
  Broadcasts an event to the UserChannel of all members of a `%Board{}`.
  """
  defp broadcast_board_updated_all_members(socket, %Board{users: users} = board) do
    Enum.each(users, fn %{id: user_id} ->
      broadcast_user_channel(user_id, @board_updated, board)
    end)

    # TODO: this may not be necessary - check again after integrating the channels into the frontend
    broadcast_board_updated(socket, board)
  end

  defp broadcast_board_updated(socket, board) do
    broadcast_board_channel(socket, @board_updated, board)
  end

  defp broadcast_board_channel(socket, event, payload) do
    broadcast_from(socket, event, payload)
  end
end
