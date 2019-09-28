defmodule PhoenixChat.IRC.Connection.Data do
  defstruct [
    :socket,
    :nick,
    :user,
    :real_name,
    channels: MapSet.new()
  ]
end
