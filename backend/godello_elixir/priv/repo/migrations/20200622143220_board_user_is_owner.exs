defmodule Godello.Repo.Migrations.BoardUserIsOwner do
  use Ecto.Migration

  def change do
    alter table(:board_users) do
      add(:is_owner, :boolean, default: false)
    end
  end
end
