defmodule LiveViewDemoWeb.FinderView do
  use LiveViewDemoWeb, :view

  def render("list.html", data) do
    ~E"""
      <section><%= list_view(data.data) %></section>
    """
  end

  def render("grid.html", data) do
    ~E"""
      <section style="display: flex">
        <%= grid_view(data.data) %>
      </section>
    """
  end

  defp list_view(data, path \\ [])

  defp list_view(data, path) when is_map(data) do
    for {key, val} <- data do
      ~E"""
        <details open>
          <summary><%= key %></summary>
          <div style="padding-left: 2rem">
            <%= list_view(val, path) %>
          </div>
        </details>
      """
    end
  end

  defp list_view(data, _path) when is_list(data) do
    {:safe, ""}
  end

  defp list_view(data, _path) when is_integer(data), do: {:safe, Integer.to_string(data)}
  defp list_view(data, _path) when is_float(data), do: {:safe, Float.to_string(data)}
  defp list_view(data, _path) when is_binary(data), do: {:safe, data}

  defp list_view(data, _path) when is_boolean(data),
    do: {:safe, if(data, do: "true", else: "false")}

  defp list_view(data, _path) when is_nil(data), do: {:safe, "null"}

  defp list_view(data, _path) do
    raise("Please implement list view for " <> data)
  end

  defp grid_view(data, path \\ [])

  defp grid_view(data, _path) when is_map(data) do
    for {key, val} <- data do
      ~E"""
        <a href="#" style="padding: 1rem; border: 1px solid #ccc" phx-click="cd" phx-value-folder-key="<%= key %>">
          <%= key %>.folder
        </a>
      """
    end
  end

  defp grid_view(data, _path) when is_list(data) do
    {:safe, ""}
  end

  defp grid_view(data, _path) when is_integer(data), do: {:safe, Integer.to_string(data)}
  defp grid_view(data, _path) when is_float(data), do: {:safe, Float.to_string(data)}
  defp grid_view(data, _path) when is_binary(data), do: {:safe, data}

  defp grid_view(data, _path) when is_boolean(data),
    do: {:safe, if(data, do: "true", else: "false")}

  defp grid_view(data, _path) when is_nil(data), do: {:safe, "null"}

  defp grid_view(data, _path) do
    raise("Please implement grid view for " <> data)
  end
end
