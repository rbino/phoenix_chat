defmodule PhoenixChat.IRC.Connection do
  @behaviour :gen_statem

  require Logger
  alias PhoenixChat.IRC.Connection.Data
  alias PhoenixChat.IRC.Connection.Handler
  alias PhoenixChat.IRC.Parser
  alias PhoenixChat.Chat
  alias PhoenixChat.Chat.Join
  alias PhoenixChat.Chat.Leave
  alias PhoenixChat.Chat.Message, as: PrivMsg
  alias PhoenixChat.Chat.User

  def start_link(init_arg) do
    :gen_statem.start_link(__MODULE__, init_arg, [])
  end

  def child_spec(args) do
    default = %{id: __MODULE__, start: {__MODULE__, :start_link, [args]}, restart: :temporary}

    Enum.reduce(args, default, fn
      {key, value}, acc when key in [:id, :start, :restart, :shutdown, :type, :modules] ->
        Map.put(acc, key, value)

      {key, _value}, _acc ->
        raise ArgumentError, "unknown key #{inspect(key)} in child specification override"
    end)
  end

  def set_socket(pid, socket) do
    :gen_statem.call(pid, {:set_socket, socket})
  end

  @impl true
  def init(_init_args) do
    {:ok, :no_socket, %Data{}}
  end

  @impl true
  def callback_mode do
    [:handle_event_function, :state_enter]
  end

  @impl true
  def handle_event({:call, from}, {:set_socket, socket}, :no_socket, data) do
    :ok = :inet.setopts(socket, active: :once)
    next_data = %{data | socket: socket}
    next_actions = [{:reply, from, :ok}]
    {:next_state, :unregistered, next_data, next_actions}
  end

  # Ignore empty messages
  def handle_event(:info, {:tcp, socket, "\r\n"}, _state, _data) do
    :ok = :inet.setopts(socket, active: :once)
    :keep_state_and_data
  end

  def handle_event(:info, {:tcp, socket, packet}, :unregistered, data) do
    :ok = :inet.setopts(socket, active: :once)

    # TODO: we should probably allow only certain messages in the unregistered state
    with {:ok, message} <- Parser.parse_message(packet),
         {:ok, new_data} <- Handler.handle_message(message, data) do
      # Handle registration
      if new_data.user != nil and new_data.nick != nil do
        {:next_state, :registered, new_data}
      else
        {:keep_state, new_data}
      end
    else
      :ok ->
        :keep_state_and_data

      {:error, :invalid_message} ->
        Logger.warn("Cannot parse message: #{inspect(packet)}")
        :keep_state_and_data
    end
  end

  def handle_event(:info, {:tcp, socket, packet}, _state, data) do
    :ok = :inet.setopts(socket, active: :once)

    with {:ok, message} <- Parser.parse_message(packet),
         {:ok, new_data} <- Handler.handle_message(message, data) do
      {:keep_state, new_data}
    else
      :ok ->
        :keep_state_and_data

      {:error, :invalid_message} ->
        Logger.warn("Cannot parse message: #{inspect(packet)}")
        :keep_state_and_data
    end
  end

  def handle_event(:info, {:tcp_closed, _socket}, state, data) do
    Logger.info("Closed")
    leave_all_chans(data)
    {:stop, :normal, [], %{data | channels: MapSet.new()}}
  end

  def handle_event(:info, %Join{} = join, _state, data) do
    Handler.handle_join(join, data)
    :keep_state_and_data
  end

  def handle_event(:info, %Leave{} = leave, _state, data) do
    Handler.handle_leave(leave, data)
    :keep_state_and_data
  end

  def handle_event(:info, %PrivMsg{} = privmsg, _state, data) do
    Handler.handle_privmsg(privmsg, data)
    :keep_state_and_data
  end

  def handle_event(:enter, :unregistered, :registered, data) do
    Handler.handle_registration(data)
    :keep_state_and_data
  end

  def handle_event(:enter, _old_state, _new_state, _data) do
    :keep_state_and_data
  end

  @impl true
  def terminate(_reason, state, data) do
    leave_all_chans(data)
  end

  defp leave_all_chans(data) do
    user = %User{
      user: data.user,
      nick: data.nick
    }

    for channel <- data.channels do
      Chat.leave_chan(channel, user)
    end

    :ok
  end
end
