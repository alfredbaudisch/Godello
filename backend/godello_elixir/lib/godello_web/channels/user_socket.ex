defmodule GodelloWeb.UserSocket do
  use Phoenix.Socket

  channel "user:*", GodelloWeb.UserChannel
  channel "board:*", GodelloWeb.BoardChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Godello.Accounts.verify_token(token) do
      {:ok, %{user_id: user_id}} ->
        {:ok,
         socket
         |> assign(:user, %{id: user_id |> ensure_id_integer()})}

      {:error, _reason} ->
        {:ok,
         socket
         |> assign(:user, nil)}
    end
  end

  def connect(_params, _socket, _) do
    :error
  end

  @impl true
  def id(%{assigns: %{current_user: %{id: user_id}}}) do
    "user_sockets:#{user_id}"
  end

  def id(_) do
    nil
  end

  defp ensure_id_integer(id) when is_binary(id) do
    id |> String.to_integer()
  end

  defp ensure_id_integer(id) when is_number(id) do
    id
  end
end
