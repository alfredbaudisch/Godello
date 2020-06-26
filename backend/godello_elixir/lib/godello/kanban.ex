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

  def get_board_info_query(id) do
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

  def get_board_info(id) do
    get_board_info_query(id)
    |> Repo.one()
  end

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

  #
  # Lists
  #

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

  def get_list_info(id) do
    Repo.get(List, id)
  end

  def create_list(%Board{id: board_id}, attrs) do
    %List{}
    |> List.changeset(attrs |> Map.put(:board_id, board_id))
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
end