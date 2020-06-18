defmodule GodelloWeb.UserController do
  use GodelloWeb, :controller

  alias Godello.Accounts
  alias Godello.Accounts.User

  action_fallback GodelloWeb.FallbackController

  def login(conn, params) do
    with {:ok, %User{} = user} <- Accounts.login(params) do
      conn
      |> put_status(:ok)
      |> put_view(GodelloWeb.UserView)
      |> render("logged_on.json", user: user, token: Accounts.create_token(user))
    end
  end
end
