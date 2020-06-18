defmodule Godello.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Godello.Repo

  alias Godello.Accounts.User

  def authenticate_user(email, plain_text_password) do
    query = from u in User, where: u.email == ^email
    case Repo.one(query) do
      nil ->
        {:error, :invalid_credentials}
      %User{password_hash: password_hash} = user ->
        if Pbkdf2.verify_pass(plain_text_password, password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
