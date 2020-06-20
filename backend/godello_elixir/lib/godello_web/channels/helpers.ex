defmodule GodelloWeb.ChannelHelpers do
  alias GodelloWeb.GenericError

  def error(details) do
    {:error, GenericError.new(details)}
  end

  def error(reason, details) do
    {:error, GenericError.new(reason, details)}
  end

  def not_authenticated do
    error("token_invalid_or_not_authenticated")
  end
end