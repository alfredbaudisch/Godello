defmodule Godello.Repo.Migrations.BoardUserIndexes do
  use Ecto.Migration

  def change do
    drop index(:board_users, [:board_id])
    create unique_index(:board_users, [:board_id, :user_id])
    create index(:board_users, [:user_id])
  end
end
