defmodule PhoenixChat.IRC.Message do
  defstruct [
    :source,
    :command,
    params: [],
    tags: %{}
  ]
end
