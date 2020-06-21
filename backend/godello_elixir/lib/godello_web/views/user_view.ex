defmodule GodelloWeb.UserView do
  use GodelloWeb, :view

  def render("logged_on.json", %{user: user, token: token}) do
    %{user: user, token: token}
  end
end
