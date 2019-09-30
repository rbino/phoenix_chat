defmodule PhoenixChat.IRC.Connection.Handler do
  require Logger
  alias PhoenixChat.IRC.Connection.Data
  alias PhoenixChat.IRC.Message
  alias PhoenixChat.Channel
  alias PhoenixChat.Channels
  alias PhoenixChat.Chat
  alias PhoenixChat.Chat.Join
  alias PhoenixChat.Chat.Leave
  alias PhoenixChat.Chat.Message, as: PrivMsg
  alias PhoenixChat.Chat.User
  alias PhoenixChat.UserRegistry

  @server_name "phoenixchat.local"

  def handle_message(%Message{command: "NICK"} = msg, data) do
    # TODO: check that nick is not already in use
    [nick] = msg.params

    case Registry.register(UserRegistry, {:nick, nick}, nil) do
      {:ok, _pid} ->
        {:ok, %{data | nick: nick}}

      {:error, {:already_registered, _pid}} ->
        err_params = ["*", nick, "Nickname is already in use"]
        err_msg = Message.new(command: "433", params: err_params)
        :ok = send_message(data.socket, err_msg)

        :ok
    end
  end

  def handle_message(%Message{command: "USER"} = msg, data) do
    [user, _, _, real_name] = msg.params

    if data.user == nil do
      {:ok, %{data | user: user, real_name: real_name}}
    else
      :ok
    end
  end

  def handle_message(%Message{command: "PING"} = msg, data) do
    [server | _] = msg.params

    pong_message = Message.new(command: "PONG", params: [server])
    :ok = send_message(data.socket, pong_message)

    :ok
  end

  def handle_message(%Message{command: "JOIN"} = msg, data) do
    # TODO: handle key param
    # TODO: handle multi-channel JOIN
    [channel | _] = msg.params

    user = %User{
      user: data.user,
      nick: data.nick
    }

    with :ok <- Chat.join_chan(channel, user),
         {:ok, pid} <- Channels.fetch(channel) do
      join_msg = Message.new(command: "JOIN", params: [channel], source: data.nick)
      :ok = send_message(data.socket, join_msg)
      # TODO: topic
      users = Channel.get_users(pid)
      # TODO: split name replies
      users_string = Map.values(users) |> Enum.join(" ")
      namreply_params = [data.nick, "@", channel, users_string]
      namreply_msg = Message.new(command: "353", params: namreply_params)
      :ok = send_message(data.socket, namreply_msg)
      endofnames_params = [data.nick, channel, ":End of /NAMES list"]

      endofnames_msg = Message.new(command: "366", params: endofnames_params)

      :ok = send_message(data.socket, endofnames_msg)

      new_channels = MapSet.put(data.channels, channel)

      {:ok, %{data | channels: new_channels}}
    else
      _ ->
        # TODO: handle failure
        :ok
    end
  end

  def handle_message(%Message{command: "MODE"} = msg, data) do
    # TODO: properly handle channel mode
    [channel | _] = msg.params

    params = [data.nick, channel, "+n"]
    message = Message.new(command: "324", params: params)
    :ok = send_message(data.socket, message)

    :ok
  end

  def handle_message(%Message{command: "PART"} = msg, data) do
    # TODO: handle multichannel and reason
    [channel | _] = msg.params

    user = %User{
      user: data.user,
      nick: data.nick
    }

    :ok = Chat.leave_chan(channel, user)

    params = [data.nick, channel]
    message = Message.new(command: "PART", params: params, source: data.nick)
    :ok = send_message(data.socket, message)

    new_channels = MapSet.delete(data.channels, channel)

    {:ok, %{data | channels: new_channels}}
  end

  def handle_message(%Message{command: "PRIVMSG"} = msg, data) do
    # TODO: handle multitarget
    [target, text] = msg.params

    user = %User{
      user: data.user,
      nick: data.nick
    }

    :ok =
      PrivMsg.new(user, target, text)
      |> Chat.send_message()

    :ok
  end

  def handle_message(msg, _data) do
    Logger.info("Unsupported Message: #{inspect(msg)}")
  end

  def handle_registration(data) do
    :ok = :gen_tcp.send(data.socket, welcome_message(data.nick))

    :ok
  end

  def handle_join(%Join{sender: sender, channel: channel}, data) do
    message = Message.new(command: "JOIN", params: [channel], source: sender.nick)
    :ok = send_message(data.socket, message)

    :ok
  end

  def handle_leave(%Leave{sender: sender, channel: channel}, data) do
    message = Message.new(command: "PART", params: [channel], source: sender.nick)
    :ok = send_message(data.socket, message)

    :ok
  end

  def handle_privmsg(%PrivMsg{sender: %User{nick: nick}}, %Data{nick: nick}) do
    # Do not reflect privmsgs
    :ok
  end

  def handle_privmsg(%PrivMsg{sender: sender, destination: destination, text: text}, data) do
    message = Message.new(command: "PRIVMSG", params: [destination, text], source: sender.nick)
    :ok = send_message(data.socket, message)

    :ok
  end

  # Use server name as source if not specified
  def send_message(socket, %Message{source: nil} = msg) do
    send_message(socket, %{msg | source: @server_name})
  end

  def send_message(socket, %Message{} = msg) do
    message_bytes = Message.serialize(msg)
    :gen_tcp.send(socket, message_bytes)
  end

  defp welcome_message(nick) do
    # TODO: brutally copy-pasted and adapted from freenode welcome message
    """
    :#{@server_name} 001 #{nick} :Welcome to the Phoenix Chat Internet Relay Chat Network #{nick}
    :#{@server_name} 002 #{nick} :Your host is #{@server_name}, running version Phoenix Chat 0.1.0
    :#{@server_name} 003 #{nick} :This server was created Thu Sep 26 2019 at 12:20:41 UTC
    :#{@server_name} 004 #{nick} #{@server_name} phoenix-chat-0.1.0 DOQRSZaghilopsuwz CFILMPQSbcefgijklmnopqrstuvz bkloveqjfI
    :#{@server_name} 005 #{nick} CHANTYPES=# EXCEPTS INVEX CHANMODES=eIbq,k,flj,CFLMPQScgimnprstuz CHANLIMIT=#:120 PREFIX=(ov)@+ MAXLIST=bqeI:100 MODES=4 NETWORK=freenode STATUSMSG=@+ CALLERID=g CASEMAPPING=rfc1459 :are supported by this server
    :#{@server_name} 005 #{nick} CHARSET=ascii NICKLEN=16 CHANNELLEN=50 TOPICLEN=390 DEAF=D FNC TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR: EXTBAN=$,ajrxz CLIENTVER=3.0 SAFELIST ELIST=CTU KNOCK :are supported by this server
    :#{@server_name} 005 #{nick} CPRIVMSG CNOTICE WHOX ETRACE :are supported by this server
    :#{@server_name} 251 #{nick} :There are 0 users and 0 invisible on 1 servers
    :#{@server_name} 252 #{nick} 0 :IRC Operators online
    :#{@server_name} 253 #{nick} 0 :unknown connection(s)
    :#{@server_name} 254 #{nick} 0 :channels formed
    :#{@server_name} 255 #{nick} :I have 0 clients and 1 servers
    :#{@server_name} 265 #{nick} 0 8096 :Current local users 0, max 8096
    :#{@server_name} 266 #{nick} 0 94773 :Current global users 0, max 94773
    :#{@server_name} 250 #{nick} :Highest connection count: 8087 (8086 clients) (1847605 connections received)
    :#{@server_name} 375 #{nick} :- #{@server_name} Message of the Day -
    :#{@server_name} 372 #{nick} :- IRC |> Phoenix LiveView
    :#{@server_name} 376 #{nick} :End of /MOTD command.
    """
  end
end
