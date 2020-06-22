defmodule GodelloWeb.ChangesetError do
  import GodelloWeb.ErrorHelpers
  alias GodelloWeb.GenericError

  def new(changeset_errors) do
    %GenericError{reason: "data_error", details: changeset_errors}
  end

  def new_translate_errors(changeset) do
    changeset
    |> translate_errors()
    |> new()
  end
end
