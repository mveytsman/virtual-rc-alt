defmodule VirtualRcAlt.PlayerMonitor do
  use GenServer

  alias VirtualRcAlt.Grid

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def monitor(view_pid), do: monitor(__MODULE__, view_pid)
  def monitor(pid, view_pid), do: GenServer.call(pid, {:monitor, view_pid})

  def init(_) do
    {:ok, MapSet.new()}
  end

  def handle_call({:monitor, view_pid}, _from, views) do
    Process.monitor(view_pid)
    {:reply, :ok, MapSet.put(views, view_pid)}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, views) do
    Grid.unregister_player(pid)
    {:noreply, MapSet.delete(views, pid)}
  end
end
