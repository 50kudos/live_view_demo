defmodule LiveViewDemo.FschemaCT do
  alias LiveViewDemo.{Repo, Fschema, TreePath}

  # Closure Table supervisor with Ecto adapter.
  use CTE,
    otp_app: :live_view_demo,
    adapter: CTE.Adapter.Ecto,
    repo: Repo,
    nodes: Fschema,
    paths: TreePath
end
