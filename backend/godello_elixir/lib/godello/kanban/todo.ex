defmodule Godello.Kanban.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :title, :string
    field :is_done, :boolean, default: false
  end

  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :is_done])
    |> validate_required([:title, :is_done])
  end
end
