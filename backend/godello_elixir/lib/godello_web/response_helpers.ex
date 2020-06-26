defmodule GodelloWeb.ResponseHelpers do

  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [put_status: 2]
  alias GodelloWeb.{ChangesetError, GenericView, ErrorView}
  alias Phoenix.{View, Socket}

  def json_response(value, %Plug.Conn{} = conn) do
    conn
    |> put_status(:ok)
    |> json(value)
  end

  def json_response(value, %Socket{} = socket) when is_list(value) do
    {:ok, %{items: value}}
    |> json_response(socket)
  end

  def json_response({:ok, value}, %Socket{} = socket) do
    {:reply, {:ok, render_response_value(value)}, socket}
  end

  def json_response({:error, %Ecto.Changeset{} = changeset}, %Socket{} = socket) do
    json_response({:error, ChangesetError.new_translate_errors(changeset)}, socket)
  end

  def json_response({:error, error}, %Socket{} = socket) do
    {:reply, {:error, View.render(ErrorView, "error.json", %{error: error})}, socket}
  end

  def json_response(value, %Socket{} = socket) do
    {:ok, value}
    |> json_response(socket)
  end

  def render_response_value(value) do
    View.render(GenericView, "generic.json", %{value: value})
  end
end
