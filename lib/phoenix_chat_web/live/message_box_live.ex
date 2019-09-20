defmodule PhoenixChatWeb.MessageBoxLive do
  use Phoenix.LiveView

  alias PhoenixChat.Chat.Message
  alias PhoenixChatWeb.MessageBoxView

  def mount(_session, socket) do
    {:ok, assign(socket, messages: [])}
  end

  def render(assigns) do
    MessageBoxView.render("message_box.html", assigns)
  end

  def handle_info(%Message{} = message, socket) do
    {:noreply, assign(socket, messages: [message])}
  end
end
