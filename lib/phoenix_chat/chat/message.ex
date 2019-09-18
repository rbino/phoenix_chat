defmodule PhoenixChat.Chat.Message do
  alias PhoenixChat.Chat.Message

  @enforce_keys [:id, :timestamp, :sender, :destination, :text]

  defstruct [
    :id,
    :timestamp,
    :sender,
    :destination,
    :text
  ]

  def new(sender, destination, text) when is_binary(destination) and is_binary(text) do
    %Message{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now(),
      sender: sender,
      destination: destination,
      text: text
    }
  end
end
