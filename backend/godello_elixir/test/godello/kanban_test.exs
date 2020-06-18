defmodule Godello.KanbanTest do
  use Godello.DataCase

  alias Godello.Kanban

  describe "boards" do
    alias Godello.Kanban.Board

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def board_fixture(attrs \\ %{}) do
      {:ok, board} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Kanban.create_board()

      board
    end

    test "list_boards/0 returns all boards" do
      board = board_fixture()
      assert Kanban.list_boards() == [board]
    end

    test "get_board!/1 returns the board with given id" do
      board = board_fixture()
      assert Kanban.get_board!(board.id) == board
    end

    test "create_board/1 with valid data creates a board" do
      assert {:ok, %Board{} = board} = Kanban.create_board(@valid_attrs)
      assert board.name == "some name"
    end

    test "create_board/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Kanban.create_board(@invalid_attrs)
    end

    test "update_board/2 with valid data updates the board" do
      board = board_fixture()
      assert {:ok, %Board{} = board} = Kanban.update_board(board, @update_attrs)
      assert board.name == "some updated name"
    end

    test "update_board/2 with invalid data returns error changeset" do
      board = board_fixture()
      assert {:error, %Ecto.Changeset{}} = Kanban.update_board(board, @invalid_attrs)
      assert board == Kanban.get_board!(board.id)
    end

    test "delete_board/1 deletes the board" do
      board = board_fixture()
      assert {:ok, %Board{}} = Kanban.delete_board(board)
      assert_raise Ecto.NoResultsError, fn -> Kanban.get_board!(board.id) end
    end

    test "change_board/1 returns a board changeset" do
      board = board_fixture()
      assert %Ecto.Changeset{} = Kanban.change_board(board)
    end
  end

  describe "lists" do
    alias Godello.Kanban.List

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def list_fixture(attrs \\ %{}) do
      {:ok, list} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Kanban.create_list()

      list
    end

    test "list_lists/0 returns all lists" do
      list = list_fixture()
      assert Kanban.list_lists() == [list]
    end

    test "get_list!/1 returns the list with given id" do
      list = list_fixture()
      assert Kanban.get_list!(list.id) == list
    end

    test "create_list/1 with valid data creates a list" do
      assert {:ok, %List{} = list} = Kanban.create_list(@valid_attrs)
      assert list.name == "some name"
    end

    test "create_list/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Kanban.create_list(@invalid_attrs)
    end

    test "update_list/2 with valid data updates the list" do
      list = list_fixture()
      assert {:ok, %List{} = list} = Kanban.update_list(list, @update_attrs)
      assert list.name == "some updated name"
    end

    test "update_list/2 with invalid data returns error changeset" do
      list = list_fixture()
      assert {:error, %Ecto.Changeset{}} = Kanban.update_list(list, @invalid_attrs)
      assert list == Kanban.get_list!(list.id)
    end

    test "delete_list/1 deletes the list" do
      list = list_fixture()
      assert {:ok, %List{}} = Kanban.delete_list(list)
      assert_raise Ecto.NoResultsError, fn -> Kanban.get_list!(list.id) end
    end

    test "change_list/1 returns a list changeset" do
      list = list_fixture()
      assert %Ecto.Changeset{} = Kanban.change_list(list)
    end
  end

  describe "cards" do
    alias Godello.Kanban.Card

    @valid_attrs %{
      todos: %{},
      description: "some description",
      is_archived: true,
      title: "some title"
    }
    @update_attrs %{
      todos: %{},
      description: "some updated description",
      is_archived: false,
      title: "some updated title"
    }
    @invalid_attrs %{todos: nil, description: nil, is_archived: nil, title: nil}

    def card_fixture(attrs \\ %{}) do
      {:ok, card} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Kanban.create_card()

      card
    end

    test "list_cards/0 returns all cards" do
      card = card_fixture()
      assert Kanban.list_cards() == [card]
    end

    test "get_card!/1 returns the card with given id" do
      card = card_fixture()
      assert Kanban.get_card!(card.id) == card
    end

    test "create_card/1 with valid data creates a card" do
      assert {:ok, %Card{} = card} = Kanban.create_card(@valid_attrs)
      assert card.todos == []
      assert card.description == "some description"
      assert card.is_archived == true
      assert card.title == "some title"
    end

    test "create_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Kanban.create_card(@invalid_attrs)
    end

    test "update_card/2 with valid data updates the card" do
      card = card_fixture()
      assert {:ok, %Card{} = card} = Kanban.update_card(card, @update_attrs)
      assert card.todos == []
      assert card.description == "some updated description"
      assert card.is_archived == false
      assert card.title == "some updated title"
    end

    test "update_card/2 with invalid data returns error changeset" do
      card = card_fixture()
      assert {:error, %Ecto.Changeset{}} = Kanban.update_card(card, @invalid_attrs)
      assert card == Kanban.get_card!(card.id)
    end

    test "delete_card/1 deletes the card" do
      card = card_fixture()
      assert {:ok, %Card{}} = Kanban.delete_card(card)
      assert_raise Ecto.NoResultsError, fn -> Kanban.get_card!(card.id) end
    end

    test "change_card/1 returns a card changeset" do
      card = card_fixture()
      assert %Ecto.Changeset{} = Kanban.change_card(card)
    end
  end
end
