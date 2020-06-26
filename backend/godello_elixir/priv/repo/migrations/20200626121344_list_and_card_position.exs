defmodule Godello.Repo.Migrations.ListAndCardPosition do
  use Ecto.Migration

  def change do
    alter table(:lists) do
      add :position, :integer, default: 0
    end

    alter table(:cards) do
      add :position, :integer, default: 0
    end
  end
end
