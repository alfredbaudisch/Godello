defmodule Godello.Repo.Migrations.BoardUsers do
  use Ecto.Migration

  def change do
    create table(:board_users) do
      add :board_id, references(:boards, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:board_users, [:board_id])
  end
end
