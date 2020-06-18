defmodule Godello.Repo.Migrations.CreateLists do
  use Ecto.Migration

  def change do
    create table(:lists) do
      add :name, :string
      add :board_id, references(:boards, on_delete: :nothing)

      timestamps()
    end

    create index(:lists, [:board_id])
  end
end
