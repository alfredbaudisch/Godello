defmodule GodelloWeb.ChannelHelpers do
  alias GodelloWeb.{GenericError, ChangesetError, GenericView, ErrorView}
  alias Phoenix.View

  def json_response({:ok, value}, socket) do
    {:reply, {:ok, View.render(GenericView, "json", %{value: value})}, socket}
  end

  def json_response({:error, %Ecto.Changeset{} = changeset}, socket) do
    json_response({:error, ChangesetError.new_translate_errors(changeset)}, socket)
  end

  def json_response({:error, error}, socket) do
    {:reply, {:error, View.render(ErrorView, "json", %{error: error})}, socket}
  end

  @spec error(any) :: {:error, GodelloWeb.GenericError.t()}
  def error(details) do
    {:error, GenericError.new(details)}
  end

  def error(reason, details) do
    {:error, GenericError.new(reason, details)}
  end

  def not_authenticated do
    error("token_invalid_or_not_authenticated")
  end
end
