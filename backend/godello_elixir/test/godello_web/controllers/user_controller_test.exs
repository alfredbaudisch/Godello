defmodule GodelloWeb.UserControllerTest do
  use GodelloWeb.ConnCase

  @moduletag :accounts

  alias Godello.Accounts

  @create_attrs %{
    first_name: "Koda",
    last_name: "Dachshund",
    email: "koda@thedachshund.com",
    password: "abc123",
    password_confirmation: "abc123"
  }

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  defp create_user(_) do
    user = fixture(:user)
    %{user: user}
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "authentication" do
    setup [:create_user]

    test "login", %{conn: conn, user: created_user} do
      conn =
        post(conn, Routes.user_path(conn, :login),
          email: @create_attrs.email,
          password: @create_attrs.password
        )

      %{"user" => user, "token" => token} = json_response(conn, 200)
      assert is_nil(user["password_hash"])
      assert user["email"] == created_user.email
      refute is_nil(token)
    end

    test "login with invalid password", %{conn: conn} do
      conn =
        post(conn, Routes.user_path(conn, :login),
          email: @create_attrs.email,
          password: "12234234"
        )

      assert json_response(conn, 400)["errors"]["reason"] == "invalid_credentials"
    end

    test "login with inexistent email", %{conn: conn} do
      conn =
        post(conn, Routes.user_path(conn, :login),
          email: "hey@koda.com",
          password: @create_attrs.password
        )

      assert json_response(conn, 400)["errors"]["reason"] == "invalid_credentials"
    end
  end
end
