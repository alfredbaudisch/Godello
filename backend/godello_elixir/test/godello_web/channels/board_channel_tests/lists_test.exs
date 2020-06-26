defmodule GodelloWeb.BoardChannelListsTest do
  use GodelloWeb.ChannelCase

  @moduletag :board_channel
  @moduletag :channels
  @moduletag :lists

  setup do
    (%{user: user, board: board} = fixtures) = create_user_and_board()
    {:ok, join_data, socket} = join_board_channel(user, board)
    %{socket: socket, join_data: join_data} |> Map.merge(fixtures)
  end

  test "create list", %{socket: socket} do
    ref = push(socket, "create_list")
    assert_reply ref, :error, errors
    assert contains_changeset_error?(errors, :name, "can't be blank")

    create_list(socket)

    assert_broadcast "list_created", broadcasted
    assert broadcasted.name == "New List"
  end

  test "delete list", %{socket: socket} do
    list = create_list(socket)

    ref = push(socket, "delete_list", %{"id" => list.id})
    assert_reply ref, :ok, deleted
    assert deleted.id == list.id

    assert_broadcast "list_deleted", broadcasted
    assert broadcasted.name == "New List"

    ref = push(socket, "delete_list", %{"id" => list.id})
    assert_reply ref, :error, error
    assert error.errors.reason == "list_not_found"
  end

  test "update list", %{socket: socket} do
    list = create_list(socket)

    ref = push(socket, "update_list", %{"id" => list.id, "name" => "New Name"})
    assert_reply ref, :ok, updated
    assert updated.id == list.id
    assert updated.name == "New Name"

    assert_broadcast "list_updated", broadcasted
    assert broadcasted.name == "New Name"

    ref = push(socket, "update_list", %{"id" => list.id, "name" => ""})
    assert_reply ref, :error, errors
    assert contains_changeset_error?(errors, :name, "can't be blank")

    ref = push(socket, "update_list", %{"id" => -1})
    assert_reply ref, :error, error
    assert error.errors.reason == "list_not_found"
  end

  defp create_list(socket) do
    ref = push(socket, "create_list", %{"name" => "New List"})
    assert_reply ref, :ok, list
    assert list.name == "New List"
    list
  end
end
