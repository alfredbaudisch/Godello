defmodule GodelloWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use GodelloWeb, :controller
      use GodelloWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: GodelloWeb

      import Plug.Conn
      import GodelloWeb.Gettext
      alias GodelloWeb.Router.Helpers, as: Routes
      import GodelloWeb.ResponseHelpers
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/godello_web/templates",
        namespace: GodelloWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import GodelloWeb.Gettext
      alias GodelloWeb.Presence
      import GodelloWeb.ResponseHelpers
      import GodelloWeb.ChannelHelpers
      import Map.Helpers
    end
  end

  defp view_helpers do
    quote do
      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import GodelloWeb.ErrorHelpers
      import GodelloWeb.Gettext
      alias GodelloWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
