defmodule DistfunSimpleWeb.PageController do
  use DistfunSimpleWeb, :controller

  alias DistfunSimple.ClusterManager

  def nodes(conn, _params) do
    render(conn, "nodes.html", %{nodes: ClusterManager.get_all_nodes()})
  end

  def health(conn, _params) do
    json(conn, %{status: "pass"})
  end
end
