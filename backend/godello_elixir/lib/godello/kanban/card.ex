defmodule Godello.Kanban.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :description, :string
    field :is_archived, :boolean, default: false
    field :title, :string
    belongs_to(:list, Godello.Kanban.List)
    embeds_many(:todos, Godello.Kanban.Todo)

    timestamps()
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:title, :description, :is_archived])
    |> validate_required([:title])
    |> cast_embed(:todos)
  end
end
