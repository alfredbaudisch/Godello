defmodule Godello.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @email_regex ~r/^([\\w-]+@([\\w-]+\\.)+[\\w-]+)/

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :password])
    |> validate_required([:first_name, :last_name, :email, :password])
    |> validate_format(:email, @email_regex)
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> put_password_hash()
    |> unique_constraint(:email)
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset), do:
    change(changeset, Pbkdf2.add_hash(password))
  defp put_password_hash(changeset), do: changeset
end
