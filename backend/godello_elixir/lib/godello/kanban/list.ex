defmodule Godello.Kanban.List do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lists" do
    field :name, :string
    belongs_to(:board, Godello.Kanban.Board)
    has_many(:cards, Godello.Kanban.Card)

    timestamps()
  end

  @doc false
  def changeset(list, attrs) do
    list
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
