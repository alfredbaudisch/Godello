defmodule GodelloWeb.GenericView do
  use GodelloWeb, :view

  def render("json", %{value: value}) do
    value
  end
end
