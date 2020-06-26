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
  end

  defp create_list(socket) do
    ref = push(socket, "create_list", %{"name" => "New List"})
    assert_reply ref, :ok, list
    assert list.name == "New List"
    list
  end

  defp create_card(%List{id: list_id}, socket) do
    ref = push(socket, "create_card", %{"title" => "New Card", "list_id" => list_id})
    assert_reply ref, :ok, card
    assert card.title == "New Card"
    card
  end
end
