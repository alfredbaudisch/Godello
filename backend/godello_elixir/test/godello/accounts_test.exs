defmodule Godello.AccountsTest do
  use Godello.DataCase

  @moduletag :accounts

  alias Godello.Accounts
  alias Godello.Accounts.User

  @valid_user %{
    first_name: "Koda",
    last_name: "Dachshund",
    email: "koda@thedachshund.com",
    password: "abc123",
    password_confirmation: "abc123"
  }

  describe "users" do
    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_user)
        |> Accounts.create_user()

      user
    end

    test "create user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_user)
      assert user.email == @valid_user.email
      refute user.password == user.password_hash
    end

    test "create invalid user" do
      assert {:error, changeset} =
               Accounts.create_user(@valid_user |> Map.put(:email, "no_email"))

      assert "has invalid format" in errors_on(changeset).email

      assert {:error, changeset} =
               Accounts.create_user(
                 @valid_user
                 |> Map.put(:password_confirmation, "random stuff")
               )

      assert "does not match confirmation" in errors_on(changeset).password_confirmation
    end

    test "email uniqueness" do
      _user = user_fixture()

      assert {:error, changeset} = Accounts.create_user(@valid_user)
      assert "has already been taken" in errors_on(changeset).email
    end
  end
end
