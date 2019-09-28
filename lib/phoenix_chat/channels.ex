defmodule PhoenixChat.Channels do
  use GenServer
  alias PhoenixChat.Channel
  alias PhoenixChat.Channels
  alias PhoenixChat.ChannelsSupervisor

  defmodule State do
    defstruct [
      :channels
    ]
  end

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: Channels)
  end

  def fetch(channel_name) do
    GenServer.call(Channels, {:get, channel_name})
  end

  def get_channels_list() do
    GenServer.call(Channels, :get_channels_list)
  end

  def ensure(channel_name) do
    with {:ok, _chan} <- fetch(channel_name) do
      :ok
    end
  end

  @impl true
  def init([]) do
    {:ok, %State{channels: %{}}}
  end

  @impl true
  def handle_call({:get, name}, _from, %State{channels: channels} = state) do
    case Map.fetch(channels, name) do
      :error ->
        {:ok, channel} = DynamicSupervisor.start_child(ChannelsSupervisor, {Channel, name})
        state = %State{state | channels: Map.put(channels, name, channel)}
        {:reply, {:ok, channel}, state}

      {:ok, channel} ->
        {:reply, {:ok, channel}, state}
    end
  end

  @impl true
  def handle_call(:get_channels_list, _from, %State{channels: channels} = state) do
    {:reply, {:ok, Map.keys(channels)}, state}
  end
end
