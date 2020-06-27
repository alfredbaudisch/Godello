defmodule Godello.Kanban.Positioning do
  @moduledoc """
  Queries and algorithms to deal with list and card positioning.
  """

  import Ecto.Query, warn: false
  alias Godello.Repo
  alias Godello.Kanban.{List, Card}
  alias Ecto.Changeset

  #
  # List
  #

  def recalculate_new_list_position(%Changeset{} = changeset, board_id) do
    recalculate_new_position(changeset, fn -> last_list_position(board_id) end)
  end

  def recalculate_list_updated_position(%List{board_id: board_id}, %Changeset{} = changeset) do
    recalculate_updated_position(changeset, fn -> last_list_position(board_id) end)
  end

  def last_list_position(board_id) do
    last_position(list_query(), board_id: board_id)
  end

  def list_positions(board_id) do
    %{
      board_id: board_id,
      lists: positions(list_query(), board_id: board_id)
    }
  end

  def recalculate_list_positions(board_id, list_id, starting_position) do
    recalculate_positions(list_query(), [board_id: board_id], list_id, starting_position)
  end

  def recalculate_list_positions_after_update(board_id, list_id, previous_position, new_position) do
    recalculate_positions_after_update(
      list_query(),
      [board_id: board_id],
      list_id,
      previous_position,
      new_position
    )
  end

  def recalculate_list_positions_after_delete(board_id, previous_position) do
    recalculate_positions_after_delete(list_query(), [board_id: board_id], previous_position)
  end

  #
  # Card
  #

  def recalculate_new_card_position(%Changeset{} = changeset, list_id) do
    recalculate_new_position(changeset, fn -> last_card_position(list_id) end)
  end

  def recalculate_card_updated_position(%Card{list_id: list_id}, %Changeset{} = changeset) do
    updated_list_id = Changeset.get_change(changeset, :list_id)
    use_list_id = updated_list_id || list_id
    recalculate_updated_position(changeset, fn -> last_card_position(use_list_id) end)
  end

  def last_card_position(list_id) do
    last_position(card_query(), list_id: list_id)
  end

  def card_positions(list_id) do
    %{
      list_id: list_id,
      cards: positions(card_query(), list_id: list_id)
    }
  end

  def recalculate_card_positions(list_id, card_id, starting_position) do
    recalculate_positions(card_query(), [list_id: list_id], card_id, starting_position)
  end

  def recalculate_card_positions_after_update(list_id, card_id, previous_position, new_position) do
    recalculate_positions_after_update(
      card_query(),
      [list_id: list_id],
      card_id,
      previous_position,
      new_position
    )
  end

  def recalculate_card_positions_after_delete(list_id, previous_position) do
    recalculate_positions_after_delete(card_query(), [list_id: list_id], previous_position)
  end

  #
  # Algorithms / Queries
  #

  defp recalculate_new_position(%Changeset{valid?: false} = changeset, _get_last_position) do
    changeset
  end

  defp recalculate_new_position(%Changeset{} = changeset, get_last_position) do
    # For now, new lists and cards are always added at the end/bottom,
    # so force the initial position to be after the last
    new_position =
      get_last_position.()
      |> case do
        last_position when is_number(last_position) ->
          last_position + 1

        _ ->
          0
      end

    Changeset.put_change(changeset, :position, new_position)
  end

  defp recalculate_updated_position(%Changeset{} = changeset, get_last_position) do
    case Changeset.get_change(changeset, :position) do
      nil ->
        changeset

      position ->
        new_position =
          get_last_position.()
          |> case do
            nil ->
              0

            last_position when position >= last_position ->
              last_position

            _ ->
              position
          end

        if position != new_position do
          Changeset.put_change(changeset, :position, new_position)
        else
          changeset
        end
    end
  end

  defp list_query do
    from(list in List)
  end

  defp card_query do
    from(card in Card)
  end

  defp last_position(base_query, parent_condition) do
    from(item in base_query,
      select: item.position,
      where: ^parent_condition,
      order_by: [desc: :position],
      limit: 1
    )
    |> Repo.one()
  end

  defp positions(base_query, parent_condition) do
    from(item in base_query,
      select: %{id: item.id, position: item.position},
      where: ^parent_condition,
      order_by: [asc: item.position]
    )
    |> Repo.all()
  end

  defp recalculate_positions(base_query, parent_condition, item_id, starting_position) do
    from(item in base_query,
      where:
        item.position >= ^starting_position and
          item.id != ^item_id,
      where: ^parent_condition
    )
    |> Repo.update_all(inc: [position: 1])
  end

  defp recalculate_positions_after_update(
         base_query,
         parent_condition,
         item_id,
         previous_position,
         new_position
       )
       when new_position > previous_position do
    from(item in base_query,
      where:
        item.position <= ^new_position and item.position > ^previous_position and
          item.id != ^item_id,
      where: ^parent_condition
    )
    |> Repo.update_all(inc: [position: -1])
  end

  defp recalculate_positions_after_update(
         base_query,
         parent_condition,
         item_id,
         previous_position,
         new_position
       )
       when new_position < previous_position do
    from(item in base_query,
      where:
        item.position >= ^new_position and item.position < ^previous_position and
          item.id != ^item_id,
      where: ^parent_condition
    )
    |> Repo.update_all(inc: [position: 1])
  end

  defp recalculate_positions_after_delete(base_query, parent_condition, previous_position) do
    from(item in base_query, where: item.position > ^previous_position, where: ^parent_condition)
    |> Repo.update_all(inc: [position: -1])
  end
end
