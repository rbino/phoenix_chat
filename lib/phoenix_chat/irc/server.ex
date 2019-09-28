defmodule PhoenixChat.IRC.Server do
  use GenServer

  alias PhoenixChat.IRC.Connection
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, 6667)

    listen_opts = [
      :binary,
      packet: :line,
      active: false,
      reuseaddr: true
    ]

    case :gen_tcp.listen(port, listen_opts) do
      {:ok, listen_socket} ->
        Logger.info("Accepting connections on port #{port}")
        {:ok, listen_socket, {:continue, :accept}}

      {:error, reason} ->
        Logger.warn("Cannot start IRC.Server: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, listen_socket) do
    with {:ok, accept_socket} <- :gen_tcp.accept(listen_socket),
         {:ok, pid} <- DynamicSupervisor.start_child(Connection.Supervisor, Connection),
         :ok <- :gen_tcp.controlling_process(accept_socket, pid),
         :ok <- Connection.set_socket(pid, accept_socket) do
      {:noreply, listen_socket, {:continue, :accept}}
    else
      {:error, reason} ->
        Logger.warn("Cannot accept new connection: #{inspect(reason)}")
        {:stop, reason}
    end
  end
end
