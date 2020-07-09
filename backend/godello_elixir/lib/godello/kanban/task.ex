defmodule Godello.Kanban.Task do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :title, :string
    field :is_done, :boolean, default: false
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :is_done])
    |> validate_required([:title, :is_done])
  end
end
