defmodule Godello.Kanban.Positioning do
  @moduledoc """
  The Kanban context.
  """

  import Ecto.Query, warn: false
  alias Godello.Repo
  alias Godello.Kanban.{List, Card}

  #
  # List
  #

  def list_positions(board_id) do
    %{
      "board" => %{
        "id" => board_id,
        "lists" => positions(list_query(), board_id: board_id)
      }
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

  def card_positions(list_id) do
    %{
      "list" => %{
        "id" => list_id,
        "cards" => positions(card_query(), list_id: list_id)
      }
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

  defp list_query do
    from(i in List)
  end

  defp card_query do
    from(i in Card)
  end

  defp positions(base_query, parent_condition) do
    from(item in base_query,
      select: %{"id" => item.id, "position" => item.position},
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
