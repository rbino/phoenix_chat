defmodule PhoenixChat.Chat.Leave do
  alias PhoenixChat.Chat.Leave
  alias PhoenixChat.Chat.User

  @enforce_keys [:id, :timestamp, :sender, :channel]

  defstruct [
    :id,
    :timestamp,
    :sender,
    :channel
  ]

  def new(%User{} = sender, channel) when is_binary(channel) do
    %Leave{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now(),
      sender: sender,
      channel: channel
    }
  end
end
