defmodule PhoenixChatWeb.MessageView do
  use PhoenixChatWeb, :view

  alias PhoenixChat.Chat.ChangeTopic
  alias PhoenixChat.Chat.Join
  alias PhoenixChat.Chat.Leave
  alias PhoenixChat.Chat.Message

  def render("any.html", %{message: %ChangeTopic{}} = assigns) do
    render("change_topic.html", assigns)
  end

  def render("any.html", %{message: %Join{}} = assigns) do
    render("join.html", assigns)
  end

  def render("any.html", %{message: %Leave{}} = assigns) do
    render("leave.html", assigns)
  end

  def render("any.html", %{message: %Message{}} = assigns) do
    render("message.html", assigns)
  end
end
