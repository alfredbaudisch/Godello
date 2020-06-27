defmodule Godello.Kanban do
  @moduledoc """
  The Kanban context.
  """

  import Ecto.Query, warn: false
  alias Godello.Repo
  alias Ecto.Changeset
  import Godello.Helpers
  alias Godello.Accounts
  alias Godello.Accounts.User
  alias Godello.Kanban.{Board, BoardUser, List, Card}
  import Godello.Kanban.Positioning

  #
  # Board
  #

  def user_has_permission_to_board?(user_id, %Board{users: users}) when is_list(users) do
    Enum.find(users, fn %{user: %{id: board_user_id}} -> board_user_id == user_id end) != nil
  end

  def user_has_permission_to_board?(user_id, board_id) when is_integer(board_id) do
    from(b in Board,
      left_join: bu in BoardUser,
      on: bu.board_id == ^board_id and bu.user_id == ^user_id,
      select: %{owner_user_id: b.owner_user_id, board_user: bu}
    )
    |> Repo.one()
    |> case do
      %{owner_user_id: owner_user_id} when owner_user_id == user_id ->
        true

      %{board_user: %{user_id: board_user_id}} when board_user_id == user_id ->
        true

      _ ->
        false
    end
  end

  def user_has_permission_to_board?(_, _) do
    false
  end

  @doc """
  Gets all the boards that the user `user_id` is a member of.
  """
  def get_boards(user_id) do
    from(b in Board,
      join: bu in BoardUser,
      on: bu.board_id == b.id and bu.user_id == ^user_id,
      where: bu.user_id == ^user_id,
      join: u in assoc(bu, :user),
      preload: [
        users: {bu, [user: u]}
      ],
      order_by: [desc: b.updated_at]
    )
    |> Repo.all()
    |> wrap_collection(:boards)
  end

  @doc """
  Gets a Board, including member users, but do not preload lists and cards.
  """
  def get_board_info(id) do
    get_board_info_query(id)
    |> Repo.one()
  end

  @doc """
  Gets a Board with member users, lists and cards preloaded.
  """
  def get_board(id) do
    from(b in get_board_info_query(id),
      left_join: l in assoc(b, :lists),
      left_join: c in assoc(l, :cards),
      preload: [
        lists: {l, [cards: c]}
      ]
    )
    |> Repo.one()
  end

  def create_board(attrs, user_id) do
    transaction_with_direct_result(fn ->
      with {:ok, board} <-
             %Board{}
             |> Board.changeset(attrs |> Map.put(:owner_user_id, user_id))
             |> Repo.insert(),
           {:ok, _board_user} <- add_board_user(board.id, user_id, true) do
        {:ok, get_board_info(board.id)}
      end
    end)
  end

  def add_board_user(board_id, user_detail, is_owner \\ false) do
    with %User{id: user_id} <- Accounts.find_user(user_detail) do
      %BoardUser{}
      |> BoardUser.changeset(%{board_id: board_id, user_id: user_id, is_owner: is_owner})
      |> Repo.insert()
    else
      nil ->
        {:error, :user_not_found}
    end
  end

  def remove_board_user(board_id, user_id) do
    from(bu in BoardUser,
      where: bu.board_id == ^board_id and bu.user_id == ^user_id
    )
    |> Repo.one()
    |> case do
      %BoardUser{is_owner: true} ->
        {:error, :user_is_owner}

      %BoardUser{} = board_user ->
        board_user |> Repo.delete()

      _ ->
        {:error, :user_not_found}
    end
  end

  def delete_board(%Board{} = board) do
    Repo.delete(board)
  end

  def update_board(%Board{} = board, attrs) do
    board
    |> Board.update_changeset(attrs)
    |> Repo.update()
  end

  defp get_board_info_query(id) do
    from(b in Board,
      join: bu in BoardUser,
      on: bu.board_id == b.id,
      join: u in assoc(bu, :user),
      where: b.id == ^id,
      preload: [
        users: {bu, [user: u]}
      ]
    )
  end

  #
  # Lists
  #

  @doc """
  Gets a list with cards preloaded.
  """
  def get_list(id) do
    from(l in List,
      join: c in assoc(l, :cards),
      preload: [
        cards: c
      ],
      where: l.id == ^id
    )
    |> Repo.one()
  end

  @doc """
  Gets a List, taking board ownership into consideration and do not preload cards.
  Returns nil if the List doesn't belong to the Board.
  """
  def get_list_info(%Board{id: board_id}, id) do
    get_list_info(id)
    |> case do
      %List{board_id: list_board_id} = list when board_id == list_board_id -> list
      %List{} -> nil
      res -> res
    end
  end

  def get_list_info(id) do
    Repo.get(List, id)
  end

  def create_list(%Board{id: board_id}, attrs) do
    %List{}
    |> List.changeset(attrs |> Map.put(:board_id, board_id))
    |> recalculate_new_list_position(board_id)
    |> Repo.insert()
  end

  def update_list(%List{} = list, attrs) do
    list
    |> List.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_list(%List{} = list) do
    Repo.delete(list)
  end

  #
  # Card
  #

  def get_card(id) do
    Repo.get(Card, id)
  end

  def get_create_card_changeset(attrs) do
    %Card{}
    |> Card.changeset(attrs)
    |> case do
      %Changeset{valid?: false} = changeset -> {:error, changeset}
      changeset -> {:ok, changeset}
    end
  end

  def create_card(%List{id: list_id}, attrs) do
    %Card{}
    |> Card.changeset(attrs |> Map.put(:list_id, list_id))
    |> recalculate_new_card_position(list_id)
    |> Repo.insert()
  end

  def update_card(
        %Card{id: card_id, position: current_position, list_id: current_list_id} = card,
        attrs,
        %Board{id: board_id}
      ) do
    card
    |> Card.changeset(attrs)
    |> run_with_valid_changeset(fn changeset ->
      list_id = Changeset.get_change(changeset, :list_id)
      position = Changeset.get_change(changeset, :position)

      set_position = fn ->
        if not is_nil(position) do
          recalculate_card_updated_position(card, changeset)
        else
          changeset
        end
      end

      # List not changed, no need to check for list ownership
      if is_nil(list_id) do
        set_position.()
      else
        # Check list ownership
        verify_list_parent(changeset, board_id, list_id, fn _list ->
          set_position.()
        end)
      end
    end)
    |> Repo.update()
    |> run_valid(fn
      # Card moved to another list, recalculate positions of the previous and the new list
      {:ok, %Card{position: new_position, list_id: new_list_id} = updated_card}
      when new_list_id != current_list_id ->
        # Recalculate positions of the originating list
        recalculate_card_positions_after_delete(current_list_id, current_position)
        # Recalculate positions of the new list
        recalculate_card_positions(new_list_id, card_id, new_position)

        {:ok, updated_card,
         {:recalculated_positions, [card_positions(current_list_id), card_positions(new_list_id)]}}

      # Changed position, recalculate positions of the current list
      {:ok, %Card{position: new_position} = updated_card} when new_position != current_position ->
        recalculate_card_positions_after_update(
          current_list_id,
          card_id,
          current_position,
          new_position
        )

        {:ok, updated_card, {:recalculated_positions, [card_positions(current_list_id)]}}

      result ->
        result
    end)
  end

  def delete_card(%Card{} = card) do
    Repo.delete(card)
  end

  #
  # Helpers
  #

  @doc """
  Check if the list_id exists and if it is part of board_id
  """
  def verify_list_parent(changeset, board_id, list_id, run_when_ok) do
    case Repo.get_by(List, id: list_id, board_id: board_id) do
      nil ->
        changeset
        |> Changeset.add_error(:list_id, "doesn't exist or doesn't belong to the current board")

      list ->
        run_when_ok.(list)
    end
  end
end
