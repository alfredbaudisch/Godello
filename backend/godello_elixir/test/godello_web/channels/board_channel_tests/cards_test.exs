defmodule GodelloWeb.BoardChannelCardsTest do
  use GodelloWeb.ChannelCase

  @moduletag :board_channel
  @moduletag :channels
  @moduletag :cards

  setup do
    (%{user: user, board: board} = fixtures) = create_user_and_board()
    {:ok, join_data, socket} = join_board_channel(user, board)
    %{socket: socket, join_data: join_data} |> Map.merge(fixtures)
  end

  test "create card", %{socket: socket} do
    list = create_list(socket)

    ref = push(socket, "create_card")
    assert_reply ref, :error, errors
    assert contains_changeset_error?(errors, :title, "can't be blank")
    assert contains_changeset_error?(errors, :list_id, "can't be blank")

    card = create_card(list, socket)
    assert card.position == 0

    assert_broadcast "card_created", broadcasted
    assert broadcasted.title == "New Card"

    card = create_card(list, socket)
    assert card.position == 1
    card = create_card(list, socket)
    assert card.position == 2
  end

  test "delete card", %{socket: socket} do
    list = create_list(socket)
    card = create_card(list, socket)

    ref = push(socket, "delete_card", %{"id" => card.id})
    assert_reply ref, :ok, deleted
    assert deleted.id == card.id

    assert_broadcast "card_deleted", broadcasted
    assert broadcasted.title == "New Card"

    ref = push(socket, "delete_card", %{"id" => card.id})
    assert_reply ref, :error, error
    assert error.errors.reason == "card_not_found"
  end

  test "update card", %{socket: socket} do
    list = create_list(socket)
    card = create_card(list, socket)

    ref = push(socket, "update_card", %{"id" => card.id, "title" => "New Name"})
    assert_reply ref, :ok, updated
    assert updated.id == card.id
    assert updated.title == "New Name"

    assert_broadcast "card_updated", broadcasted
    assert broadcasted.title == "New Name"

    ref = push(socket, "update_card", %{"id" => card.id, "title" => ""})
    assert_reply ref, :error, errors
    assert contains_changeset_error?(errors, :title, "can't be blank")

    ref = push(socket, "update_card", %{"id" => -1})
    assert_reply ref, :error, error
    assert error.errors.reason == "card_not_found"

    ref = push(socket, "update_card", %{"id" => card.id, "list_id" => -1})
    assert_reply ref, :error, errors

    assert contains_changeset_error?(
             errors,
             :list_id,
             "doesn't exist or doesn't belong to the current board"
           )
  end

  describe "card positioning" do
    test "in the same list", %{socket: socket} do
      list = create_list(socket)
      card1 = create_card(list, socket) |> as_json()
      card2 = create_card(list, socket) |> as_json()
      card3 = create_card(list, socket) |> as_json()

      ref = push(socket, "update_card", %{card1 | "position" => 2})
      assert_reply ref, :ok, updated
      assert updated.position == 2

      assert_broadcast "cards_repositioned", repositions
      assert_position(repositions, card1["id"], 2)
      assert_position(repositions, card2["id"], 0)
      assert_position(repositions, card3["id"], 1)
    end

    test "to another list", %{socket: socket} do
      list1 = create_list(socket)
      card11 = create_card(list1, socket) |> as_json()
      card12 = create_card(list1, socket) |> as_json()
      card13 = create_card(list1, socket) |> as_json()

      list2 = create_list(socket, "List 2")
      card21 = create_card(list2, socket) |> as_json()
      card22 = create_card(list2, socket) |> as_json()
      card23 = create_card(list2, socket) |> as_json()

      ref = push(socket, "update_card", %{card22 | "list_id" => list1.id, "position" => 1})
      assert_reply ref, :ok, updated
      assert updated.list_id == list1.id
      assert updated.position == 1

      assert_broadcast "card_updated", broadcasted
      assert broadcasted.list_id == list1.id
      assert broadcasted.position == 1

      #
      # Assert repositioning for both lists
      #
      assert_positions = fn repositions ->
        if repositions["list"]["id"] == list2.id do
          assert_position(repositions, card21["id"], 0)
          assert_position(repositions, card23["id"], 1)
        else
          assert_position(repositions, card11["id"], 0)
          assert_position(repositions, card22["id"], 1)
          assert_position(repositions, card12["id"], 2)
          assert_position(repositions, card13["id"], 3)
        end
      end

      assert_broadcast "cards_repositioned", repositions1
      assert_positions.(repositions1)
      assert_broadcast "cards_repositioned", repositions2
      assert_positions.(repositions2)

      # Make sure we received positions for both lists
      assert (repositions1["list"]["id"] == list1.id and repositions2["list"]["id"] == list2.id) or
               (repositions2["list"]["id"] == list1.id and repositions1["list"]["id"] == list2.id)

      #
      # Make the 2nd list have just one item, then empty
      #
      ref = push(socket, "update_card", %{card21 | "list_id" => list1.id, "position" => 2})
      assert_reply ref, :ok, _updated

      assert_positions = fn repositions ->
        if repositions["list"]["id"] == list2.id do
          assert_position(repositions, card23["id"], 0)
        else
          assert_position(repositions, card11["id"], 0)
          assert_position(repositions, card22["id"], 1)
          assert_position(repositions, card21["id"], 2)
          assert_position(repositions, card12["id"], 3)
          assert_position(repositions, card13["id"], 4)
        end
      end

      assert_broadcast "cards_repositioned", repositions1
      assert_positions.(repositions1)
      assert_broadcast "cards_repositioned", repositions2
      assert_positions.(repositions2)

      ref = push(socket, "update_card", %{card23 | "list_id" => list1.id, "position" => 0})
      assert_reply ref, :ok, _updated

      assert_positions = fn repositions ->
        if repositions["list"]["id"] == list2.id do
          assert Enum.empty?(repositions["list"]["cards"])
        else
          assert_position(repositions, card23["id"], 0)
          assert_position(repositions, card11["id"], 1)
          assert_position(repositions, card22["id"], 2)
          assert_position(repositions, card21["id"], 3)
          assert_position(repositions, card12["id"], 4)
          assert_position(repositions, card13["id"], 5)
        end
      end

      assert_broadcast "cards_repositioned", repositions1
      assert_positions.(repositions1)
      assert_broadcast "cards_repositioned", repositions2
      assert_positions.(repositions2)

      #
      # Move back to the empty list
      #
      ref = push(socket, "update_card", %{card12 | "list_id" => list2.id})
      assert_reply ref, :ok, _updated

      assert_positions = fn repositions ->
        if repositions["list"]["id"] == list2.id do
          assert_position(repositions, card12["id"], 0)
        else
          assert_position(repositions, card23["id"], 0)
          assert_position(repositions, card11["id"], 1)
          assert_position(repositions, card22["id"], 2)
          assert_position(repositions, card21["id"], 3)
          assert_position(repositions, card13["id"], 4)
        end
      end

      assert_broadcast "cards_repositioned", repositions1
      assert_positions.(repositions1)
      assert_broadcast "cards_repositioned", repositions2
      assert_positions.(repositions2)
    end

    test "when deleting card", %{socket: socket} do
      throw("IMPLEMENT REPOSITION FOR CARD DELETE")
    end
  end

  defp assert_position(%{"list" => %{"cards" => cards}}, card_id, position) do
    Enum.find(cards, fn %{"id" => found_id} -> found_id == card_id end)
    |> case do
      %{"position" => found_position} -> assert found_position == position
      _ -> throw("Not found")
    end
  end

  defp create_list(socket, name \\ "New List") do
    ref = push(socket, "create_list", %{"name" => name})
    assert_reply ref, :ok, list
    assert list.name == name
    list
  end

  defp create_card(%List{id: list_id}, socket) do
    ref = push(socket, "create_card", %{"title" => "New Card", "list_id" => list_id})
    assert_reply ref, :ok, card
    assert card.title == "New Card"
    card
  end
end
