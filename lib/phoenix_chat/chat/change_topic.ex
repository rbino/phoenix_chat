defmodule PhoenixChat.Chat.ChangeTopic do
  alias PhoenixChat.Chat.ChangeTopic

  @enforce_keys [:id, :timestamp, :sender, :channel, :topic]

  defstruct [
    :id,
    :timestamp,
    :sender,
    :channel,
    :topic
  ]

  def new(sender, channel, topic) when is_binary(channel) and is_binary(topic) do
    %ChangeTopic{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now(),
      sender: sender,
      channel: channel,
      topic: topic
    }
  end
end
