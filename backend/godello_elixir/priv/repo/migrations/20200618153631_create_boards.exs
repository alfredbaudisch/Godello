defmodule Godello.Repo.Migrations.CreateBoards do
  use Ecto.Migration

  def change do
    create table(:boards) do
      add :name, :string
      add :owner_user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:boards, [:owner_user_id])
  end
end
