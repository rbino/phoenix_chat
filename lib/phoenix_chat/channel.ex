defmodule PhoenixChat.Channel do
  use GenServer
  alias PhoenixChat.Chat
  alias PhoenixChat.Chat.Join
  alias PhoenixChat.Chat.Leave
  alias PhoenixChat.Chat.Message
  alias PhoenixChat.Chat.User

  defmodule State do
    defstruct [
      :backlog,
      :users
    ]
  end

  @impl true
  def init(chan) do
    :ok = Chat.subscribe_chan(chan)

    {:ok,
     %State{
       backlog: [],
       users: %{}
     }}
  end

  @impl true
  def handle_call(:get_users, _from, %State{users: users} = state) do
    {:reply, users, state}
  end

  @impl true
  def handle_call(:get_backlog, _from, %State{backlog: backlog} = state) do
    {:reply, backlog, state}
  end

  @impl true
  def handle_info(%Join{sender: user} = msg, %State{} = state) do
    %State{
      backlog: backlog,
      users: users
    } = state

    %User{
      user: user,
      nick: nick
    } = user

    {:noreply, %State{state | backlog: [msg | backlog], users: Map.put(users, user, nick)}}
  end

  @impl true
  def handle_info(%Leave{sender: user} = msg, %State{} = state) do
    %State{
      backlog: backlog,
      users: users
    } = state

    %User{
      user: user
    } = user

    {:noreply, %State{state | backlog: [msg | backlog], users: Map.delete(users, user)}}
  end

  @impl true
  def handle_info(%Message{} = msg, %State{} = state) do
    %State{
      backlog: backlog
    } = state

    {:noreply, %State{state | backlog: [msg | backlog]}}
  end
end
