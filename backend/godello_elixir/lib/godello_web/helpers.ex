defmodule GodelloWeb.Helpers do
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [put_status: 2]
  alias GodelloWeb.{ChangesetError, GenericView, ErrorView}
  alias Phoenix.View

  def json_response({:ok, value}, socket) do
    {:reply, {:ok, View.render(GenericView, "generic.json", %{value: value})}, socket}
  end

  def json_response({:error, %Ecto.Changeset{} = changeset}, socket) do
    json_response({:error, ChangesetError.new_translate_errors(changeset)}, socket)
  end

  def json_response({:error, error}, socket) do
    {:reply, {:error, View.render(ErrorView, "error.json", %{error: error})}, socket}
  end

  def json_response(%Plug.Conn{} = conn, value) do
    conn
    |> put_status(:ok)
    |> json(value)
  end
end
