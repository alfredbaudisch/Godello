defmodule GodelloWeb.ChannelHelpers do
  alias GodelloWeb.GenericError
  alias GodelloWeb.Endpoint

  @user_channel "user:"

  @spec error(any) :: {:error, GodelloWeb.GenericError.t()}
  def error(details) do
    {:error, GenericError.new(details)}
  end

  def error(reason, details) do
    {:error, GenericError.new(reason, details)}
  end

  def not_authenticated do
    error("token_invalid_or_not_authenticated")
  end

  def broadcast_user_channel(user_id, event, payload) do
    Endpoint.broadcast("#{@user_channel}#{user_id}", event, payload)
  end
end
