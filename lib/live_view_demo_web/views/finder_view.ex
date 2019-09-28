defmodule LiveViewDemoWeb.FinderView do
  use LiveViewDemoWeb, :view
  alias LiveViewDemo.{FschemaCT}
  alias Ecto.Changeset

  def node_changeset(fschema) do
    Changeset.change(fschema)
  end

  def render_assert(form, :string), do: render("assert/string.html", f: form)
  def render_assert(form, :integer), do: render("assert/integer.html", f: form)
  def render_assert(_form, _), do: {:safe, ""}

  def render("tree.html", assigns) do
    leaf_wrapper = fn ancestor_node, depth, opts ->
      selected? = opts.selected_node.id == ancestor_node.id

      ~E"""
        <div
          class="<%= if(selected?, do: 'bg-blue-900', else: 'hover:bg-gray-800') %> cursor-pointer"
          style="padding-left: <%= 1.25 * depth %>rem"
          phx-click="select_node"
          phx-value-node-id="<%= ancestor_node.id %>"
        >
          <span class="text-blue-400"><%= ancestor_node.key %></span> : <span class="text-yellow-400"><%= ancestor_node.type %></span>
        </div>
      """
    end

    node_wrapper = fn ancestor_node, subtree_view, depth, opts ->
      selected? = opts.selected_node.id == ancestor_node.id

      ~E"""
        <details open>
          <summary
            class="<%= if(selected?, do: 'bg-blue-900', else: 'hover:bg-gray-800') %> cursor-pointer"
            style="padding-left: <%= 1.25 * depth %>rem"
            phx-click="select_node"
            phx-value-node-id="<%= ancestor_node.id %>"
          >
            <%= if ancestor_node.type == :array do %>
              <%= ancestor_node.key %> [ ]
            <% else %>
              <%= ancestor_node.key %>
            <% end %>
          </summary>
          <div>
            <%= subtree_view.(opts) %>
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
    leaf_wrapper = fn ancestor_node, _depth, opts ->
      leaf_node =
        case ancestor_node.type do
          :string ->
            ~E"""
              <%= label class: "flex items-center my-1" do %>
                <span class="mr-4 flex-1 text-blue-400"><%= ancestor_node.key %>:</span>
                <%= text_input(opts.f, Integer.to_string(ancestor_node.id) |> String.to_atom(), class: "bg-gray-900 w-5/6 p-1", "phx-focus": "select_node", "phx-value-node-id": ancestor_node.id) %>
              <% end %>
              <%= error_tag(opts.f, Integer.to_string(ancestor_node.id) |> String.to_atom(), class: "block mt-1 text-red-600 w-5/6 self-end") %>
            """

          :integer ->
            ~E"""
              <%= label class: "flex items-center my-1" do %>
                <span class="mr-4 flex-1 text-blue-400"><%= ancestor_node.key %>:</span>
                <%= number_input(opts.f, Integer.to_string(ancestor_node.id) |> String.to_atom(), class: "bg-gray-900 p-1 w-5/6", "phx-focus": "select_node", "phx-value-node-id": ancestor_node.id) %>
                <% end %>
              <%= error_tag(opts.f, Integer.to_string(ancestor_node.id) |> String.to_atom(), class: "block mt-1 text-red-600 w-5/6 self-end") %>
            """

          :boolean ->
            ~E"""
              <%= label class: "flex items-center my-1" do %>
                <span class="w-1/6 text-blue-400"><%= ancestor_node.key %>:</span>
                <%= checkbox(opts.f, Integer.to_string(ancestor_node.id) |> String.to_atom(), class: "bg-gray-900 p-1", "phx-focus": "select_node", "phx-value-node-id": ancestor_node.id) %>
              <% end %>
            """

          _ ->
            {:safe, ""}
        end

      ~E"""
        <div class="flex flex-col">
          <%= leaf_node %>
        </div>
      """
    end

    node_wrapper = fn
      %{type: :object} = ancestor_node, subtree_view, _depth, opts ->
        ~E"""
          <h1 class="my-4"><%= ancestor_node.key %></h1>
          <div>
            <%= subtree_view.(opts) %>
          </div>
        """

      %{type: :array} = ancestor_node, subtree_view, _depth, opts ->
        ~E"""
          <h1 class="my-4"><%= ancestor_node.key %></h1>
          <div>
            <%= subtree_view.(opts) %>
          </div>
        """

      _ancestor_node, _subtree_view, _depth, _opts ->
        {:safe, ""}
    end

    assigns =
      assigns
      |> put_in([:opts, :leaf_wrapper], leaf_wrapper)
      |> put_in([:opts, :node_wrapper], node_wrapper)

    ~E"""
      <%= f = form_for @output_changeset, "#", [as: :output, phx_change: :output] %>
        <%= tree_view(@tree, 0, Map.put(@opts, :f, f)) %>
      </form>
    """
  end

  def render("output_json.html", assigns) do
    ~E"""
      <pre class="flex bg-gray-900">
        <code class="bg-transparent json" phx-hook="syntaxHighlight"><%= @output_json %></code>
      </pre>
    """
  end

  def render_map(tree, id_values) do
    leaf_wrapper = fn ancestor_node, _depth, opts ->
      Map.put(
        %{},
        ancestor_node.key,
        Map.get(id_values, "#{ancestor_node.id}" |> String.to_atom())
      )
    end

    node_wrapper = fn
      ancestor_node, subtree_view, _depth, opts ->
        subtree_view =
          subtree_view.(opts)
          |> Enum.reduce(%{}, fn val, acc -> Map.merge(val, acc) end)

        Map.put(%{}, ancestor_node.key, subtree_view)
    end

    tree_view(tree, 0, %{leaf_wrapper: leaf_wrapper, node_wrapper: node_wrapper})
  end

  defp tree_view(%{nodes: nodes, paths: paths, ancestor: ancestor_} = tree, depth, opts) do
    ancestor_node = Map.get(nodes, ancestor_)

    children_paths =
      paths
      |> Enum.filter(fn %_{ancestor: a, descendant: d, depth: depth} ->
        a != d && a == ancestor_ && a && depth == 1
      end)
      |> Enum.map(fn tree_path -> [tree_path.ancestor, tree_path.descendant] end)

    case children_paths do
      [] ->
        opts.leaf_wrapper.(ancestor_node, depth, opts)

      children ->
        subtree_view_fn = fn opts_ ->
          children
          |> Enum.map(fn [_, descendant] ->
            tree_view(%{tree | ancestor: descendant}, depth + 1, opts_)
          end)
        end

        opts.node_wrapper.(ancestor_node, subtree_view_fn, depth, opts)
    end
  end
end
