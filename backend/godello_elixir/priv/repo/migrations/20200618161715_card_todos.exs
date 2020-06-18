defmodule Godello.Repo.Migrations.CardTodos do
  use Ecto.Migration

  def change do
    rename table("cards"), :checklist, to: :todos
  end
end
