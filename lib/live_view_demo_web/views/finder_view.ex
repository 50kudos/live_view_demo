defmodule LiveViewDemoWeb.FinderView do
  use LiveViewDemoWeb, :view
  alias LiveViewDemo.FschemaCT

  def render("tree.html", assigns) do
    ~E"""
      <%= tree_view(@tree, []) %>
    """
  end

  defp tree_view(data, path, opts \\ [])

  defp tree_view(%{nodes: nodes, paths: paths, ancestor: ancestor_} = tree, path, opts) do
    ancestor_node = Map.get(nodes, ancestor_)
    paths = Enum.filter(paths, fn [a, d] -> a != d end)

    children =
      paths
      |> Enum.filter(fn [ancestor, descendant] ->
        !(ancestor in (Enum.map(paths, fn [a, _] -> a end) -- [ancestor]) &&
            descendant in (Enum.map(paths, fn [_, d] -> d end) -- [descendant]))
      end)
      |> Enum.filter(fn [ancestor, descendant] -> ancestor_ == ancestor end)

    case children do
      [] ->
        ~E"""
          <div><%= ancestor_node.key %></div>
        """

      children ->
        subtree_view =
          children
          |> Enum.map(fn [_, descendant] ->
            tree_view(%{tree | ancestor: descendant, paths: paths -- children}, path, opts)
          end)

        ~E"""
          <details open>
            <summary><%= ancestor_node.key %></summary>
            <div style="padding-left: 2rem">
              <%= subtree_view %>
            </div>
          </details>
        """
    end
  end
end
