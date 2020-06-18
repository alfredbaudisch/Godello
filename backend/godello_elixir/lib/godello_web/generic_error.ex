defmodule GodelloWeb.GenericError do
  require GodelloWeb.Gettext

  @derive Jason.Encoder
  defstruct reason: "", details: ""

  def new(reason, details) do
    %__MODULE__{details: details, reason: reason}
  end

  def new(details) do
    new(details, details)
  end

  @doc """
  @param reason The details asset id WITHOUT the domain appended. Example:
  - reason: invalid_email
  - domain: users
  - asset_id: users.invalid_email

  Call should be: `new_translatable("invalid_email", "users")`
  """
  def new_translatable(reason, domain \\ "errors", bindings \\ %{})

  def new_translatable(reason, domain, bindings) when is_atom(reason) do
    new_translatable(reason |> to_string, domain, bindings)
  end

  def new_translatable(reason, domain, bindings) do
    new(reason, Gettext.dgettext(GodelloWeb.Gettext, domain, domain <> "." <> reason, bindings))
  end
end
