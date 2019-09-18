defmodule PhoenixChatWeb.MessageBoxLive do
  use Phoenix.LiveView

  alias PhoenixChat.Chat.Message
  alias PhoenixChat.Chat.User
  alias PhoenixChatWeb.MessageBoxView

  def mount(_session, socket) do
    Process.send_after(self(), :do_ping, 1000)
    {:ok, assign(socket, messages: [])}
  end

  def render(assigns) do
    MessageBoxView.render("message_box.html", assigns)
  end

  def handle_info(:do_ping, socket) do
    sender = %User{
      user: "Ping User",
      nick: "ping_user"
    }

    id = socket.assigns[:message_id] || 0

    message = %Message{
      id: id,
      timestamp: DateTime.utc_now(),
      sender: sender,
      destination: "#foo",
      text: "Ping"
    }

    send(self(), message)
    Process.send_after(self(), :do_pong, 1000)
    {:noreply, assign(socket, message_id: id + 1)}
  end

  def handle_info(:do_pong, socket) do
    sender = %User{
      user: "Pong User",
      nick: "pong_user"
    }

    id = socket.assigns[:message_id]

    message = %Message{
      id: id,
      timestamp: DateTime.utc_now(),
      sender: sender,
      destination: "#foo",
      text: "Pong"
    }

    send(self(), message)
    Process.send_after(self(), :do_ping, 1000)
    {:noreply, assign(socket, message_id: id + 1)}
  end

  def handle_info(%Message{} = message, socket) do
    {:noreply, assign(socket, messages: [message])}
  end
end
