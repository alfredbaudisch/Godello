defmodule GodelloWeb.UserController do
  use GodelloWeb, :controller

  alias Godello.Accounts
  alias Godello.Accounts.User

  action_fallback GodelloWeb.FallbackController

  def login(conn, params) do
    with {:ok, %User{} = user} <- Accounts.login(params) do
      render_user_with_token(conn, user)
    end
  end

  def create(conn, params) do
    with {:ok, %User{} = user} <- Accounts.create_user(params) do
      render_user_with_token(conn, user)
    end
  end

  defp render_user_with_token(conn, user) do
    conn
    |> json_response(%{user: user, token: Accounts.create_token(user)})
  end
end
