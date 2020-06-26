defmodule GodelloWeb.TestHelpers do
  alias Godello.{Accounts, Kanban}
  import ExUnit.Assertions, only: [assert: 2, assert: 1]

  @valid_user %{
    first_name: "Koda",
    last_name: "Dachshund",
    email: "koda@thedachshund.com",
    password: "abc123",
    password_confirmation: "abc123"
  }

  @valid_board %{
    name: "Project Board"
  }

  def as_json(item) do
    Jason.encode!(item)
    |> Jason.decode!()
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@valid_user)
      |> Accounts.create_user()

    user
  end

  def board_fixture(%Accounts.User{id: user_id}, attrs \\ %{}) do
    {:ok, board} =
      attrs
      |> Enum.into(@valid_board)
      |> Kanban.create_board(user_id)

    board
  end

  def create_user_and_board do
    user = user_fixture()
    %{user: user, board: board_fixture(user)}
  end

  def json_response(payload) do
    Jason.encode!(payload)
    |> Jason.decode!()
  end

  def assert_key(%{__meta__: _} = payload, key, compare_to) do
    assert json_response(payload)[key] == compare_to
  end

  def assert_key(payload, key, compare_to) do
    assert payload[key] == compare_to
  end

  def contains_changeset_error?(%{errors: %{details: details, reason: "data_error"}}, key, error) do
    Enum.reduce(details, false, fn
      {k, v}, _ when k == key and v == error ->
        true

      {k, v}, _ when k == key and is_list(v) ->
        not is_nil(Enum.find(v, nil, fn e -> e == error end))

      _, final ->
        final
    end)
  end

  def contains_changeset_error?(_, _, _) do
    false
  end

  def contains_changeset_error?(%{errors: %{details: details, reason: "data_error"}}, key) do
    Enum.reduce(details, false, fn
      {k, _}, _ when k == key -> true
      _, final -> final
    end)
  end

  def contains_changeset_error?(_, _) do
    false
  end
end
