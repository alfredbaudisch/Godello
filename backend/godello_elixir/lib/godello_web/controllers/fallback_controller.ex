defmodule GodelloWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use GodelloWeb, :controller
  alias GodelloWeb.{GenericError, ChangesetError}

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(GodelloWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, %GenericError{} = error}) do
    conn
    |> put_status(:bad_request)
    |> put_view(GodelloWeb.ErrorView)
    |> render("json", error: error)
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> call({:error, ChangesetError.new_translate_errors(changeset)})
  end

  def call(conn, {:error, error}) do
    conn
    |> call({:error, GenericError.new_translatable(error)})
  end
end
