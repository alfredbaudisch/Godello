defmodule Godello.Accounts do
  @context GodelloWeb.Endpoint
  @max_age 60 * 60 * 24 * 365
  @salt "Godello.Accounts.UserToken"

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

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_token(%User{id: user_id}, salt \\ @salt) do
    Phoenix.Token.sign(@context, salt, %{
      user_id: user_id
    })
  end

  def verify_token(token, salt \\ @salt),
    do: Phoenix.Token.verify(@context, salt, token, max_age: @max_age)
end
