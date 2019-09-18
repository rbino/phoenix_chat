defmodule PhoenixChatWeb.PhoenixChatLive do
  use Phoenix.LiveView

  def mount(_session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
      <h1>Phoenix Chat</h1>
    """
  end
end
