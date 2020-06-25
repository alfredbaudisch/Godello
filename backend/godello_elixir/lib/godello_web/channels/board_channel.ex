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
  @update_board "update_board"
  @delete_board "delete_board"
  @add_member "add_member"
  @remove_member "remove_member"

  # Out
  @board_updated "board_updated"
  @board_deleted "board_deleted"
  @board_membership_added "board_membership_added"
  @board_membership_removed "board_membership_removed"

  #
  # EVENTS IN
  #

  @impl true
  def handle_in(@get_board, _params, %{assigns: %{board_id: board_id}} = socket) do
    Kanban.get_board(board_id)
    |> json_response(socket)
  end

  def handle_in(@update_board, params, %{assigns: %{board_id: board_id}} = socket) do
    with %Board{} = board <- Kanban.get_board_info(board_id),
         {:ok, updated_board} = result <- Kanban.update_board(board, params) do
      # TODO: may cause duplicate data, because of data also going through user channels. Maybe remove me:
      broadcast_board_updated(socket, updated_board)
      broadcast_board_updated_all_members(socket, updated_board, board)
      result
    end
    |> json_response(socket)
  end

  def handle_in(@delete_board, _params, %{assigns: %{board_id: board_id}} = socket) do
    # The list of members is needed, so fetch the board in advance
    with %Board{} = board <- Kanban.get_board_info(board_id),
         {:ok, _del_board} <- Kanban.delete_board(board) do
      broadcast_to_all_board_members(@board_deleted, board)
      {:ok, %{deleted: true, board_id: board_id}}
    else
      nil -> {:error, GenericError.new("board_not_found", "This Board has already been deleted.")}
    end
    |> json_response(socket)
  end

  def handle_in(@add_member, %{"email" => email}, %{assigns: %{board_id: board_id}} = socket) do
    with {:ok, board_user} <- Kanban.add_board_user(board_id, email) do
      board = get_board_info(socket)
      broadcast_board_updated(socket, board)

      # Notify the added user about their new membership
      broadcast_user_channel(board_user.user_id, @board_membership_added, board)

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

      # Notify the removed user about their membership removed
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

  defp broadcast_board_updated_all_members(socket, %Board{} = board) do
    broadcast_board_updated_all_members(socket, board, board)
  end

  defp broadcast_board_updated_all_members(socket, %Board{} = board, %Board{} = board_user_list) do
    broadcast_to_all_board_members(@board_updated, board, board_user_list)

    # TODO: check whether this is really necessary after integrating channels to the frontend,
    # because it would mean receibing duplicate data (both in the user channel and board channel)
    broadcast_board_updated(socket, board)
  end

  defp broadcast_to_all_board_members(event, %Board{} = board) do
    broadcast_to_all_board_members(event, board, board)
  end

  @doc """
  Broadcasts an event to the UserChannel of all members of a `%Board{}`. It's possible
  to provide a different list of members from the desired board content to submit.
  """
  defp broadcast_to_all_board_members(event, %Board{} = board, %Board{users: board_users}) do
    Enum.each(board_users, fn %{id: user_id} ->
      broadcast_user_channel(user_id, event, board)
    end)
  end

  defp broadcast_board_updated(socket, board) do
    broadcast_board_channel(socket, @board_updated, board)
  end

  defp broadcast_board_channel(socket, event, payload) do
    broadcast_from(socket, event, payload)
  end
end
