defmodule DistfunSimpleWeb.PageLive do
  use DistfunSimpleWeb, :live_view

  alias DistfunSimple.ClusterManager

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        assign(socket, :nodes, ClusterManager.get_all_nodes_and_subscribe())
      else
        assign(socket, :nodes, ClusterManager.get_all_nodes())
      end

    {:ok, socket}
  end

  @impl true
  def handle_info({:nodes_updated, new_nodes}, socket) do
    socket = assign(socket, :nodes, new_nodes)

    {:noreply, socket}
  end
end
