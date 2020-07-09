defmodule Godello.Kanban.Card do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset

  @derive {Jason.Encoder,
           only: [:id, :title, :list_id, :description, :is_archived, :position, :tasks]}
  schema "cards" do
    field :description, :string
    field :is_archived, :boolean, default: false
    field :title, :string
    field :position, :integer, default: 0
    belongs_to(:list, Godello.Kanban.List)
    embeds_many(:tasks, Godello.Kanban.Task)

    timestamps()
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:title, :description, :is_archived, :list_id, :position])
    |> validate_required([:title, :list_id, :position])
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> cast_embed(:tasks)
    |> force_position_when_list_is_changed(card)
  end

  defp force_position_when_list_is_changed(%Changeset{valid?: true} = changeset, %__MODULE__{
         id: id,
         position: current_position
       })
       when is_number(id) do
    case Changeset.get_change(changeset, :list_id) do
      nil ->
        changeset

      _ ->
        # List changed
        case Changeset.get_change(changeset, :position) do
          nil ->
            # No position provided, so force current position
            Changeset.force_change(changeset, :position, current_position)

          _ ->
            changeset
        end
    end
  end

  defp force_position_when_list_is_changed(changeset, _card) do
    changeset
  end
end
