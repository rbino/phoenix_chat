defmodule PhoenixChatWeb.PhoenixChatLive do
  use Phoenix.LiveView, container: {:section, class: "row h-100"}

  alias PhoenixChatWeb.ChatView

  def mount(_session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ChatView.render("chat.html", assigns)
  end
end
