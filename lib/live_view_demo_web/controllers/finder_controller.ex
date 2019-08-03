defmodule LiveViewDemoWeb.FinderController do
  use LiveViewDemoWeb, :controller

  plug :put_layout, "finder.html"

  def index(conn, _params) do
    live_render(conn, LiveViewDemoWeb.FinderLive, session: %{})
  end
end
