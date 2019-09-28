defmodule PhoenixChat.IRC.Message do
  defstruct [
    :source,
    :command,
    params: [],
    tags: %{}
  ]

  alias PhoenixChat.IRC.Message

  def new(opts) do
    struct(Message, opts)
  end
end
