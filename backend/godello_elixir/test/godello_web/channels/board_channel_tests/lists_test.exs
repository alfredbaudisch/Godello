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

    list = create_list(socket)
    assert list.position == 0

    assert_broadcast "list_created", broadcasted
    assert broadcasted.name == "New List"

    list = create_list(socket)
    assert list.position == 1
    list = create_list(socket)
    assert list.position == 2
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

  describe "list positioning" do
    @tag :list_position
    test "move lists", %{socket: socket} do
      list1 = create_list(socket) |> as_json()
      list2 = create_list(socket) |> as_json()
      list3 = create_list(socket) |> as_json()
      list4 = create_list(socket) |> as_json()

      assert list1["position"] == 0
      assert list2["position"] == 1
      assert list3["position"] == 2
      assert list4["position"] == 3

      ref = push(socket, "update_list", %{list1 | "position" => 2})
      assert_reply ref, :ok, _updated

      assert_broadcast "lists_repositioned", repositions
      assert_position(repositions, list2["id"], 0)
      assert_position(repositions, list3["id"], 1)
      assert_position(repositions, list1["id"], 2)
      assert_position(repositions, list4["id"], 3)

      ref = push(socket, "update_list", %{list4 | "position" => 0})
      assert_reply ref, :ok, _updated

      assert_broadcast "lists_repositioned", repositions
      assert_position(repositions, list4["id"], 0)
      assert_position(repositions, list2["id"], 1)
      assert_position(repositions, list3["id"], 2)
      assert_position(repositions, list1["id"], 3)
    end

    @tag :list_position
    test "when deleting list", %{socket: socket} do
      list1 = create_list(socket) |> as_json()
      list2 = create_list(socket) |> as_json()
      list3 = create_list(socket) |> as_json()
      list4 = create_list(socket) |> as_json()

      assert list1["position"] == 0
      assert list2["position"] == 1
      assert list3["position"] == 2
      assert list4["position"] == 3

      ref = push(socket, "delete_list", list1)
      assert_reply ref, :ok, _updated

      assert_broadcast "lists_repositioned", repositions
      assert_position(repositions, list2["id"], 0)
      assert_position(repositions, list3["id"], 1)
      assert_position(repositions, list4["id"], 2)

      ref = push(socket, "delete_list", list3)
      assert_reply ref, :ok, _updated

      assert_broadcast "lists_repositioned", repositions
      assert_position(repositions, list2["id"], 0)
      assert_position(repositions, list4["id"], 1)
    end
  end

  defp create_list(socket) do
    ref = push(socket, "create_list", %{"name" => "New List"})
    assert_reply ref, :ok, list
    assert list.name == "New List"
    list
  end

  defp assert_position(repositions, list_id, position) do
    Enum.find(repositions.lists, fn %{id: found_id} -> found_id == list_id end)
    |> case do
      %{position: found_position} -> assert found_position == position
      _ -> throw("Not found")
    end
  end
end
