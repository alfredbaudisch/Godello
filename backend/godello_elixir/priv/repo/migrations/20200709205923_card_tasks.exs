defmodule Godello.Repo.Migrations.CardTasks do
  use Ecto.Migration

  def change do
    rename table("cards"), :todos, to: :tasks
  end
end
