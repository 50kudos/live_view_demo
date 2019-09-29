defmodule LiveViewDemoWeb.FinderLive do
  use Phoenix.LiveView, container: {:div, class: "w-full"}
  alias LiveViewDemo.{Repo, FschemaCT, Fschema, TreePath}
  require Ecto.Query

  def render(assigns) do
    Phoenix.View.render(LiveViewDemoWeb.FinderView, "index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok,
     socket
     |> assign(:data, initial_data())}
  end

  defp initial_data do
    fsch =
      if fsch = Repo.get_by(Fschema, key: "v0.2") do
        fsch
      else
        {:ok, fsch} = Repo.insert(%Fschema{key: "v0.2", type: :object})
        {:ok, _paths} = FschemaCT.insert(fsch.id, fsch.id)

        {:ok, red_women} = Repo.insert(%Fschema{key: "Red Women", type: :object})

        {:ok, red_women_word} =
          Repo.insert(%Fschema{
            key: "word",
            type: :string,
            assert: %{maxLength: 30, minLength: 5, pattern: ".*death\\?$"}
          })

        {:ok, arya} = Repo.insert(%Fschema{key: "Arya", type: :object})

        {:ok, arya_word} =
          Repo.insert(%Fschema{
            key: "word",
            type: :string,
            assert: %{maxLength: 10, minLength: 1, pattern: ".*today!$"}
          })

        {:ok, _paths} = FschemaCT.insert(red_women.id, fsch.id)
        {:ok, _paths} = FschemaCT.insert(red_women_word.id, red_women.id)
        {:ok, _paths} = FschemaCT.insert(arya.id, fsch.id)
        {:ok, _paths} = FschemaCT.insert(arya_word.id, arya.id)

        {:ok, wolves} = Repo.insert(%Fschema{key: "wolves", type: :array})
        {:ok, wolf} = Repo.insert(%Fschema{key: "wolf", type: :object})

        {:ok, wolfe_name} = Repo.insert(%Fschema{key: "name", type: :string})
        {:ok, allegiance} = Repo.insert(%Fschema{key: "allegiance", type: :string})

        {:ok, appeared_in} =
          Repo.insert(%Fschema{
            key: "appeared in eps (count)",
            type: :integer,
            assert: %{minimum: 1, maximum: 5}
          })

        {:ok, status} = Repo.insert(%Fschema{key: "alive?", type: :boolean})

        {:ok, _paths} = FschemaCT.insert(wolves.id, fsch.id)
        {:ok, _paths} = FschemaCT.insert(wolf.id, wolves.id)
        {:ok, _paths} = FschemaCT.insert(wolfe_name.id, wolf.id)
        {:ok, _paths} = FschemaCT.insert(allegiance.id, wolf.id)
        {:ok, _paths} = FschemaCT.insert(appeared_in.id, wolf.id)
        {:ok, _paths} = FschemaCT.insert(status.id, wolf.id)

        fsch
      end

    {:ok, tree} = FschemaCT.tree(fsch.id)

    tree =
      Map.update!(tree, :paths, fn paths ->
        Enum.map(paths, fn [a, d] ->
          Repo.one(Ecto.Query.from(TreePath, where: [ancestor: ^a, descendant: ^d]))
        end)
      end)

    id_values =
      Enum.reduce(tree.nodes, %{}, fn {id, record}, acc ->
        Map.put(acc, Integer.to_string(id), nil)
      end)

    output_changeset = to_types_params(id_values, tree.nodes) |> output_changeset()

    tree = Map.put(tree, :ancestor, fsch.id)

    %{
      tree: tree,
      output_changeset: output_changeset,
      output_json: to_json(tree, output_changeset),
      opts: %{
        selected_node: Map.get(tree.nodes, fsch.id)
      }
    }
  end

  def handle_event("select_node", %{"node-id" => node_id}, socket) do
    {:noreply,
     update(socket, :data, fn data ->
       selected_node = Map.get(data.tree.nodes, String.to_integer(node_id), %Fschema{})
       put_in(data, [:opts, :selected_node], selected_node)
     end)}
  end

  def handle_event("assert_change", %{"fschema" => fschema}, socket) do
    data = socket.assigns.data

    selected_node =
      data.opts.selected_node
      |> Fschema.changeset(fschema)
      |> Ecto.Changeset.apply_changes()

    tree_nodes = Map.update!(data.tree.nodes, selected_node.id, fn _ -> selected_node end)

    types_params =
      to_types_params(
        data.output_changeset.changes
        |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, Atom.to_string(k), v) end),
        tree_nodes
      )

    output_changeset = output_changeset(types_params)

    {:noreply,
     update(socket, :data, fn data ->
       data =
         data
         |> put_in([:opts, :selected_node], selected_node)
         |> put_in([:tree, :nodes], tree_nodes)
         |> put_in([:output_changeset], output_changeset)

       data
       |> put_in([:output_json], to_json(data.tree, output_changeset))
     end)}
  end

  def handle_event("output", %{"output" => outputs}, socket) do
    types_params = to_types_params(outputs, socket.assigns.data.tree.nodes)
    output_changeset = output_changeset(types_params, socket.assigns.data.tree.nodes)

    {:noreply,
     update(socket, :data, fn data ->
       data =
         data
         |> put_in([:output_changeset], output_changeset)

       data
       |> put_in([:output_json], to_json(data.tree, output_changeset))
     end)}
  end

  defp to_types_params(id_values, nodes) do
    Enum.reduce(id_values, [%{}, %{}], fn {id, value}, [type, param] ->
      fsch = Map.get(nodes, String.to_integer(id))
      id_atom = Integer.to_string(fsch.id) |> String.to_atom()
      [Map.put(type, id_atom, fsch), Map.put(param, id_atom, value)]
    end)
  end

  defp output_changeset(_, nodes \\ [])

  defp output_changeset([fschs, params], nodes) do
    types = Enum.reduce(fschs, %{}, fn {id, fsch}, acc -> Map.put(acc, id, fsch.type) end)
    changeset = Ecto.Changeset.change({%{}, types}, params)
    changeset = %{changeset | action: :replace}

    params
    |> Enum.reduce(changeset, fn {field, val}, changeset ->
      fsch = Map.get(fschs, field)

      case {fsch.type, fsch.assert} do
        {:boolean, _} ->
          changeset
          |> Ecto.Changeset.cast(Map.take(params, [field]), [field])

        {_, nil} ->
          changeset

        {:integer, assert} ->
          changeset
          |> Ecto.Changeset.cast(Map.take(params, [field]), [field])
          |> Ecto.Changeset.validate_number(field,
            greater_than_or_equal_to: assert.minimum,
            less_than_or_equal_to: assert.maximum
          )

        {:string, assert} ->
          changeset
          |> Ecto.Changeset.validate_length(field, min: assert.minLength, max: assert.maxLength)
          |> (fn ch ->
                case Regex.compile(assert.pattern) do
                  {:ok, regex} ->
                    Ecto.Changeset.validate_format(ch, field, regex)

                  {:error, _} ->
                    ch
                end
              end).()

        {_, _} ->
          changeset
      end
    end)
  end

  defp to_json(tree, changeset) do
    if changeset.valid? do
      Ecto.Changeset.apply_changes(changeset)
      |> (fn id_values ->
            LiveViewDemoWeb.FinderView.render_map(tree, id_values)
          end).()
    else
      %{}
    end
    |> Jason.encode!(pretty: true)
  end
end
