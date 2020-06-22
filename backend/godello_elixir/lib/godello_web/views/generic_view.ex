defmodule GodelloWeb.GenericView do
  use GodelloWeb, :view

  def render("generic.json", %{value: value}) do
    value
  end
end
