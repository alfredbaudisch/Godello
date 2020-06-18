defmodule GodelloWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  def translate_error(msg) when is_atom(msg) do
    translate_error(msg |> to_string())
  end

  def translate_error(msg) when is_binary(msg) do
    translate_error({msg, %{}})
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(GodelloWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(GodelloWeb.Gettext, "errors", msg, opts)
    end
  end
end
