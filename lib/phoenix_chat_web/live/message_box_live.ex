defmodule PhoenixChatWeb.MessageBoxLive do
  use Phoenix.LiveView, container: {:section, class: "row h-100"}

  alias PhoenixChat.Channels
  alias PhoenixChat.Chat
  alias PhoenixChat.Chat.ChangeTopic
  alias PhoenixChat.Chat.Join
  alias PhoenixChat.Chat.Leave
  alias PhoenixChat.Chat.Message
  alias PhoenixChatWeb.MessageBoxView

  def mount(_session, socket) do
    user = %PhoenixChat.Chat.User{user: "foo", nick: "foo"}
    PhoenixChat.Chat.join_chan("#test", user)

    {:ok, chan} = Channels.fetch("#test")
    chan_topic = PhoenixChat.Channel.get_topic(chan)
    users_map = PhoenixChat.Channel.get_users(chan)

    chan_users = Map.values(users_map)

    socket =
      socket
      |> assign(messages: [])
      |> assign(user: user)
      |> assign(chan: "#test")
      |> assign(chan_topic: chan_topic)
      |> assign(chan_users: chan_users)
      |> assign(input_reset_id: UUID.uuid1())

    {:ok, socket}
  end

  def render(assigns) do
    MessageBoxView.render("message_box.html", assigns)
  end

  def handle_event("enter_message", %{"code" => "Enter", "value" => text} = _event, socket) do
    %{
      chan: chan,
      user: user
    } = socket.assigns

    Message.new(user, chan, text)
    |> Chat.send_message()

    socket =
      socket
      |> assign(input_reset_id: UUID.uuid1())

    {:noreply, socket}
  end

  def handle_event("enter_message", _event, socket) do
    {:noreply, socket}
  end

  def handle_info(%ChangeTopic{topic: new_topic} = change_topic, socket) do
    socket =
      socket
      |> assign(messages: [change_topic])
      |> assign(chan_topic: new_topic)

    {:noreply, socket}
  end

  def handle_info(%Join{} = join, socket) do
    users_list =
      [join.sender.nick | socket.assigns[:chan_users]]
      |> Enum.sort()
      |> Enum.dedup()

    socket =
      socket
      |> assign(messages: [join])
      |> assign(chan_users: users_list)

    {:noreply, socket}
  end

  def handle_info(%Leave{} = leave, socket) do
    users_list =
      socket.assigns[:chan_users]
      |> List.delete(leave.sender.nick)
      |> Enum.sort()

    socket =
      socket
      |> assign(messages: [leave])
      |> assign(chan_users: users_list)

    {:noreply, socket}
  end

  def handle_info(%Message{} = message, socket) do
    {:noreply, assign(socket, messages: [message])}
  end
end
