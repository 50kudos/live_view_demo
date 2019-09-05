defmodule LiveViewDemoWeb.FinderLive do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(LiveViewDemoWeb.FinderView, "index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok,
     socket
     |> assign(:display_template, "list.html")
     |> assign(:data, sample_data())}
  end

  defp sample_data do
    %{
      map_of_inner: %{a: 1, b: 2, c: 3},
      map_of_map: %{a: %{a_1: 11}, b: 2, c: 3},
      array_of_inner: ~w(a b c d e),
      array_of_map: [%{a: 1, b: 2}, %{a: 3, b: 4}]
    }
  end

  def handle_event("display_grid", _value, socket) do
    {:noreply,
     socket
     |> update(:display_template, fn _ -> "grid.html" end)
     |> assign(:data, sample_data())}
  end

  def handle_event("display_list", _value, socket) do
    {:noreply,
     socket
     |> update(:display_template, fn _ -> "list.html" end)
     |> assign(:data, sample_data())}
  end

  def handle_event("cd", %{"folder-key" => folder}, socket) do
    {:noreply,
     update(socket, :data, fn data ->
       %{data | map_of_map: cd(data.map_of_map, folder)}
     end)}
  end

  defp cd(source, destination) do
    Map.get(source, String.to_existing_atom(destination))
  end
end
