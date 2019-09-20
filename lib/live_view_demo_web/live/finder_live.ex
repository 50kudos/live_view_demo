defmodule LiveViewDemoWeb.FinderLive do
  use Phoenix.LiveView, container: {:div, class: "w-full sm:w-10/12 sm:py-12"}
  alias LiveViewDemo.{Repo, FschemaCT, Fschema, TreePath}

  def render(assigns) do
    Phoenix.View.render(LiveViewDemoWeb.FinderView, "index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok,
     socket
     |> assign(:data, initial_data())}
  end

  defp initial_data do
    unless fsch = Repo.get_by(Fschema, key: "root") do
      {:ok, fsch} = Repo.insert(%Fschema{key: "root", type: :object})
      {:ok, _paths} = FschemaCT.insert(fsch.id, fsch.id)
    end

    {:ok, tree} = FschemaCT.tree(fsch.id)

    %{
      tree: Map.put(tree, :ancestor, fsch.id)
    }
  end
end
