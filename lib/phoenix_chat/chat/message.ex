defmodule PhoenixChat.Chat.Message do
  defstruct [
    :id,
    :timestamp,
    :sender,
    :destination,
    :text
  ]
end
