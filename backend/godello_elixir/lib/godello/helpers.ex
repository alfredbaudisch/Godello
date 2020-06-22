defmodule Godello.Helpers do
  alias Godello.Repo

  def wrap_collection(items, name) when is_list(items) do
    %{} |> Map.put(name, items)
  end

  def wrap_collection(other) do
    other
  end

  def transaction_with_direct_result(run) do
    {_, res} = Repo.transaction(run)
    res
  end
end
