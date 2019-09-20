defmodule PhoenixChatWeb.PhoenixChatLive do
  use Phoenix.LiveView

  alias PhoenixChatWeb.ChatView

  def mount(_session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ChatView.render("chat.html", assigns)
  end
end
