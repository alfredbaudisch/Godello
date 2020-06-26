defmodule Godello.Kanban.List do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :board_id, :name, :position, :cards]}
  schema "lists" do
    field :name, :string
    field :position, :integer, default: 0
    belongs_to(:board, Godello.Kanban.Board)
    has_many(:cards, Godello.Kanban.Card)

    timestamps()
  end

  @doc false
  def changeset(list, attrs) do
    list
    |> cast(attrs, [:board_id, :name, :position])
    |> validate_required([:board_id, :name, :position])
    |> validate_number(:position, greater_than_or_equal_to: 0)
  end

  def update_changeset(list, attrs) do
    list
    |> cast(attrs, [:name, :position])
    |> validate_required([:name, :position])
    |> validate_number(:position, greater_than_or_equal_to: 0)
  end
end
