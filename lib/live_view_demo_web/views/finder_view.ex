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
    leaf_wrapper = fn
      ancestor_node, _depth, %{ui: :table} = opts ->
        ~E"""
          <%= text_input(opts.f, Integer.to_string(ancestor_node.id) |> String.to_atom(), class: "bg-gray-900 p-1 w-full border border-gray-800", "phx-focus": "select_node", "phx-value-node-id": ancestor_node.id) %>
        """

      ancestor_node, _depth, opts ->
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
      ancestor_node, subtree_view, _, %{ui: :table} = opts ->
        {:ok, children} = FschemaCT.descendants(ancestor_node.id, depth: 1, nodes: true)

        records =
          [1, 2]
          |> Enum.with_index()
          |> Enum.map(fn {record, index} ->
            opts =
              opts
              |> put_in([:f], %{opts.f | name: opts.f.name <> "[#{index}]"})

            ~E"""
              <article class="flex">
                <%= subtree_view.(opts) %>
              </article>
            """
          end)

        ~E"""
          <header class="flex justify-around mb-2">
            <%= for child <- children do %>
              <span class="text-blue-400"><%= child.key %></span>
            <% end %>
          </header>

          <%= records %>
        """

      %{type: :object} = ancestor_node, subtree_view, _depth, opts ->
        ~E"""
          <h1 class="my-1 font-semibold"><%= ancestor_node.key %></h1>
          <div>
            <%= subtree_view.(opts) %>
          </div>
        """

      %{type: :array} = ancestor_node, subtree_view, _depth, opts ->
        opts =
          opts
          |> put_in([:f], %{opts.f | name: opts.f.name <> "[#{ancestor_node.id}]"})
          |> put_in([:ui], :table)

        ~E"""
          <h1 class="my-1 font-semibold"><%= ancestor_node.key %></h1>
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

  # Bypass changeset validation here since (ecto)schemaless doesn't work with embed.
  # So the form validation is not working for embed currently.
  # We would have to change underline validator and data structure actually!
  def render_map(tree, id_values) do
    leaf_wrapper = fn
      ancestor_node, _depth, %{id_vals: id_vals} ->
        value = Map.get(id_vals, "#{ancestor_node.id}")

        if value == "" do
          Map.put(%{}, ancestor_node.key, value)
        else
          case ancestor_node do
            %{type: :boolean} ->
              case Ecto.Type.cast(:boolean, value) do
                {:ok, val} ->
                  Map.put(%{}, ancestor_node.key, val)

                :error ->
                  Map.put(%{}, ancestor_node.key, value)
              end

            %{type: :integer} ->
              case Ecto.Type.cast(:integer, value) do
                {:ok, val} ->
                  Map.put(%{}, ancestor_node.key, val)

                :error ->
                  Map.put(%{}, ancestor_node.key, value)
              end

            _ ->
              Map.put(%{}, ancestor_node.key, value)
          end
        end

      ancestor_node, _depth, opts ->
        value = Map.get(id_values, "#{ancestor_node.id}" |> String.to_atom())
        Map.put(%{}, ancestor_node.key, value)
    end

    node_wrapper = fn
      ancestor_node, subtree_view, _depth, %{items: nil} = opts ->
        subtree_view.(opts)
        |> Enum.reduce(%{}, fn val, acc -> Map.merge(val, acc) end)

      ancestor_node, subtree_view, _depth, %{items: indexed_id_values} = opts ->
        indexed_id_values
        |> Enum.map(fn {_index, id_vals} ->
          subtree_view.(Map.put(opts, :id_vals, id_vals))
          |> Enum.reduce(%{}, fn val, acc -> Map.merge(val, acc) end)
        end)

      %{type: :object} = ancestor_node, subtree_view, _depth, opts ->
        subtree_view =
          subtree_view.(opts)
          |> Enum.reduce(%{}, fn val, acc -> Map.merge(val, acc) end)

        Map.put(%{}, ancestor_node.key, subtree_view)

      %{type: :array} = ancestor_node, subtree_view, _depth, opts ->
        indexed_id_values = Map.get(id_values, "#{ancestor_node.id}" |> String.to_atom())
        [subtree_view] = subtree_view.(Map.put(opts, :items, indexed_id_values))
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
