defmodule LiveViewDemoWeb.FinderView do
  use LiveViewDemoWeb, :view

  def render("tree.html", assigns) do
    leaf_wrapper = fn ancestor_node, depth, opts ->
      ~E"""
        <div
          class="<%= if(opts.selected_node == ancestor_node.id, do: 'bg-gray-700', else: 'hover:bg-gray-800') %> cursor-pointer"
          style="padding-left: <%= 1.25 * depth %>rem"
          phx-click="select_node"
          phx-value-node-id="<%= ancestor_node.id %>"
        >
          <%= ancestor_node.key %>.<%= ancestor_node.type %>
        </div>
      """
    end

    node_wrapper = fn ancestor_node, subtree_view, depth, opts ->
      ~E"""
        <details open>
          <summary
            class="<%= if(opts.selected_node == ancestor_node.id, do: 'bg-gray-700', else: 'hover:bg-gray-800') %> cursor-pointer"
            style="padding-left: <%= 1.25 * depth %>rem"
            phx-click="select_node"
            phx-value-node-id="<%= ancestor_node.id %>"
          >
            <%= ancestor_node.key %>
          </summary>
          <div>
            <%= subtree_view %>
          </div>
        </details>
      """
    end

    assigns =
      assigns
      |> put_in([:opts, :leaf_wrapper], leaf_wrapper)
      |> put_in([:opts, :node_wrapper], node_wrapper)

    ~E"""
      <%= tree_view(@tree, 0, @opts) %>
    """
  end

  def render("output.html", assigns) do
    leaf_wrapper = fn ancestor_node, depth, opts ->
      ~E"""
        <div>
          <%= ancestor_node.key %>.<%= ancestor_node.type %>
        </div>
      """
    end

    node_wrapper = fn ancestor_node, subtree_view, depth, opts ->
      ~E"""
        <h1><%= ancestor_node.key %>.<%= ancestor_node.type %></h1>
        <div>
          <%= subtree_view %>
        </div>
      """
    end

    assigns =
      assigns
      |> put_in([:opts, :leaf_wrapper], leaf_wrapper)
      |> put_in([:opts, :node_wrapper], node_wrapper)

    ~E"""
      <%= tree_view(@tree, 0, @opts) %>
    """
  end

  defp tree_view(%{nodes: nodes, paths: paths, ancestor: ancestor_} = tree, depth, opts) do
    ancestor_node = Map.get(nodes, ancestor_)
    paths = Enum.filter(paths, fn [a, d] -> a != d end)

    children =
      paths
      |> Enum.filter(fn [ancestor, descendant] ->
        !(ancestor in (Enum.map(paths, fn [a, _] -> a end) -- [ancestor]) &&
            descendant in (Enum.map(paths, fn [_, d] -> d end) -- [descendant]))
      end)
      |> Enum.filter(fn [ancestor, _] -> ancestor_ == ancestor end)

    case children do
      [] ->
        opts.leaf_wrapper.(ancestor_node, depth, opts)

      children ->
        subtree_view =
          children
          |> Enum.map(fn [_, descendant] ->
            tree_view(%{tree | ancestor: descendant, paths: paths -- children}, depth + 1, opts)
          end)

        opts.node_wrapper.(ancestor_node, subtree_view, depth, opts)
    end
  end
end
