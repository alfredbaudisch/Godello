defmodule GodelloWeb.UserController do
  use GodelloWeb, :controller

  alias Godello.Accounts
  alias Godello.Accounts.User

  action_fallback GodelloWeb.FallbackController

  def login(conn, params) do
    with {:ok, %User{} = user} <- Accounts.login(params) do
      conn
      |> put_status(:ok)
      |> render_user_with_token(user)
    end
  end

  def create(conn, params) do
    with {:ok, %User{} = user} <- Accounts.create_user(params) do
      conn
      |> put_status(:created)
      |> render_user_with_token(user)
    end
  end

  defp render_user_with_token(conn, user) do
    conn
    |> put_view(GodelloWeb.UserView)
    |> render("logged_on.json", user: user, token: Accounts.create_token(user))
  end
end
