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

  def run_with_valid_changeset(%Ecto.Changeset{valid?: true} = changeset, run) do
    run.(changeset)
  end

  def run_with_valid_changeset(%Ecto.Changeset{} = changeset, _run) do
    changeset
  end

  def run_valid({:ok, _v} = payload, run) do
    run.(payload)
  end

  def run_valid(value, _run) do
    value
  end
end
