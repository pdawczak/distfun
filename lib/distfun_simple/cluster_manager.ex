defmodule DistfunSimple.ClusterManager do
  use GenServer

  require Logger

  defmodule State do
    defstruct me: nil, other_nodes: [], listeners: nil

    def new(me) do
      %State{me: me, other_nodes: [], listeners: MapSet.new()}
    end

    def me(%State{me: me}) do
      me
    end

    def all(%State{me: me, other_nodes: other_nodes}) do
      [me | other_nodes]
    end

    def add_node(%State{} = state, node) do
      sorted_other_nodes = Enum.sort([node | state.other_nodes])
      %{state | other_nodes: sorted_other_nodes}
    end

    def remove_node(%State{} = state, node) do
      %{state | other_nodes: state.other_nodes -- [node]}
    end

    def register_listener(%State{} = state, listener) do
      %{state | listeners: MapSet.put(state.listeners, listener)}
    end

    def deregister_listener(%State{} = state, listener) do
      %{state | listeners: MapSet.delete(state.listeners, listener)}
    end
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_all_nodes() do
    GenServer.call(__MODULE__, :get_all_nodes)
  end

  def get_all_nodes_and_subscribe() do
    GenServer.call(__MODULE__, {:get_all_nodes_and_subscribe, self()})
  end

  def init(:ok) do
    Logger.debug("Starting Cluster Manager")

    :net_kernel.monitor_nodes(true)

    {:ok, State.new(node())}
  end

  def handle_call(:get_all_nodes, _from, %State{} = state) do
    {:reply, State.all(state), state}
  end

  def handle_call({:get_all_nodes_and_subscribe, listener}, _from, %State{} = state) do
    Logger.debug("'#{inspect(listener)}' subscribing")

    new_state = State.register_listener(state, listener)

    Process.monitor(listener)

    {:reply, State.all(state), new_state}
  end

  def handle_info({:nodeup, node}, %State{} = state) do
    Logger.debug("'#{node}' connecting")

    new_state =
      state
      |> State.add_node(node)
      |> broadcast()

    {:noreply, new_state}
  end

  def handle_info({:nodedown, node}, %State{} = state) do
    Logger.debug("'#{node}' disconnecting")

    new_state =
      state
      |> State.remove_node(node)
      |> broadcast()

    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %State{} = state) do
    Logger.debug("'#{inspect(pid)}' listener unsubscribing")

    new_state = State.deregister_listener(state, pid)

    {:noreply, new_state}
  end

  defp broadcast(%State{} = state) do
    Enum.each(
      state.listeners,
      &send(&1, {:nodes_updated, State.all(state)})
    )

    state
  end
end
