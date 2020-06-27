defmodule GodelloWeb.BoardChannel do
  use GodelloWeb, :channel
  @board_channel "board:"

  alias Godello.Kanban
  alias Godello.Kanban.{Board, List, Card, Positioning}
  alias GodelloWeb.GenericError
  alias Ecto.Changeset

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
            socket = assign(socket, :board, Board.to_basic(board))
            send(self(), :after_join)
            {:ok, render_response_value(%{board: board}), socket}
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
  @create_list "create_list"
  @update_list "update_list"
  @delete_list "delete_list"
  @create_card "create_card"
  @update_card "update_card"
  @delete_card "delete_card"

  # Out
  @board_updated "board_updated"
  @board_deleted "board_deleted"
  @board_membership_added "board_membership_added"
  @board_membership_removed "board_membership_removed"
  @list_created "list_created"
  @list_updated "list_updated"
  @list_deleted "list_deleted"
  @card_created "card_created"
  @card_updated "card_updated"
  @card_deleted "card_deleted"
  @cards_repositioned "cards_repositioned"

  #
  # EVENTS: Board
  #

  @impl true
  def handle_in(@get_board, _params, %{assigns: %{board: %{id: board_id}}} = socket) do
    Kanban.get_board(board_id)
    |> json_response(socket)
  end

  def handle_in(@update_board, params, socket) do
    with %Board{} = board <- get_board_info(socket),
         {:ok, updated_board} = result <- Kanban.update_board(board, params) do
      # TODO: may cause duplicate data, because of data also going through user channels. Maybe remove me:
      broadcast_board_updated(socket, updated_board)
      broadcast_board_updated_all_members(socket, updated_board, board)
      result
    end
    |> json_response(socket)
  end

  def handle_in(@delete_board, _params, socket) do
    # The list of members is needed, so fetch the board in advance
    with %Board{} = board <- get_board_info(socket),
         {:ok, _del_board} <- Kanban.delete_board(board) do
      broadcast_to_all_board_members(@board_deleted, board)
      {:ok, %{deleted: true, board: board}}
    else
      nil -> {:error, GenericError.new("board_not_found", "This Board has already been deleted.")}
    end
    |> json_response(socket)
  end

  def handle_in(@add_member, %{"email" => email}, %{assigns: %{board: %{id: board_id}}} = socket) do
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
        %{assigns: %{board: %{id: board_id}}} = socket
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
  # EVENTS: List
  #

  def handle_in(@create_list, params, %{assigns: %{board: board}} = socket) do
    Kanban.create_list(board, params |> atomize_keys())
    |> broadcast_flow(socket, @list_created)
    |> json_response(socket)
  end

  def handle_in(@update_list, %{"id" => list_id} = params, socket) do
    get_list_and_run(
      list_id,
      fn list -> Kanban.update_list(list, params) end,
      @list_updated,
      socket
    )
  end

  def handle_in(@delete_list, %{"id" => list_id}, socket) do
    get_list_and_run(list_id, &Kanban.delete_list/1, @list_deleted, socket)
  end

  #
  # EVENTS: Card
  #

  def handle_in(@create_card, params, %{assigns: %{board: board}} = socket) do
    # Let's get the list_id from params in order to get the list, making
    # sure it exists and belongs to this board
    with {:ok, %Changeset{valid?: true, changes: %{list_id: list_id}}} <-
           Kanban.get_create_card_changeset(params),
         %List{} = list <- Kanban.get_list_info(board, list_id),
         {:ok, _card} = result <- Kanban.create_card(list, params |> atomize_keys()) do
      broadcast_flow(result, socket, @card_created)
    else
      nil -> {:error, GenericError.new("list_not_found", "List not found")}
      error -> error
    end
    |> json_response(socket)
  end

  def handle_in(@update_card, %{"id" => card_id} = params, %{assigns: %{board: board}} = socket) do
    with %Card{} = card <- Kanban.get_card(card_id) do
      Kanban.update_card(card, params, board)
      |> case do
        {:ok, updated_card, {:recalculated_positions, lists}} ->
          lists =
            Enum.reduce(lists, %{}, fn list, acc ->
              Map.put(acc, list.list_id, Map.take(list, [:cards]))
            end)

          broadcast(socket, @cards_repositioned, %{lists: lists})

          {:ok, updated_card}

        result ->
          result
      end
    else
      nil -> {:error, GenericError.new("card_not_found", "Card not found")}
      error -> error
    end
    |> broadcast_flow(socket, @card_updated)
    |> json_response(socket)
  end

  def handle_in(@delete_card, %{"id" => card_id}, socket) do
    get_card_and_run(card_id, &Kanban.delete_card/1, @card_deleted, socket)
  end

  #
  # HELPERS
  #

  defp get_list_and_run(list_id, run, broadcast_event, %{assigns: %{board: board}} = socket) do
    with %List{} = list <- Kanban.get_list_info(board, list_id),
         {:ok, _list_updated} = result <- run.(list) do
      broadcast_flow(result, socket, broadcast_event)
    else
      nil -> {:error, GenericError.new("list_not_found", "List not found")}
      error -> error
    end
    |> json_response(socket)
  end

  defp get_card_and_run(card_id, run, broadcast_event, socket) do
    with %Card{} = card <- Kanban.get_card(card_id),
         {:ok, _card_updated} = result <- run.(card) do
      broadcast_flow(result, socket, broadcast_event)
    else
      nil -> {:error, GenericError.new("card_not_found", "Card not found")}
      error -> error
    end
    |> json_response(socket)
  end

  defp get_board_info(%Phoenix.Socket{assigns: %{board: %{id: board_id}}}) do
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

  defp broadcast_flow({:ok, value} = payload, socket, event) do
    broadcast_board_channel(socket, event, value)
    payload
  end

  defp broadcast_flow(payload, _socket, _event) do
    payload
  end

  defp broadcast_board_channel(socket, event, payload) do
    broadcast_from(socket, event, payload)
  end
end
