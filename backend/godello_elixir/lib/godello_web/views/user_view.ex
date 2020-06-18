defmodule GodelloWeb.UserView do
  use GodelloWeb, :view

  def render("logged_on.json", %{user: user, token: token}) do
    %{user: render_one(user, __MODULE__, "user.json"), token: token}
  end

  def render("show.json", %{user: user}) do
    %{user: render_one(user, __MODULE__, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{id: user.id, first_name: user.first_name, last_name: user.last_name, email: user.email}
  end
end
