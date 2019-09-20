defmodule LiveViewDemo.TreePath do
  use Ecto.Schema
  import Ecto.Changeset
  alias LiveViewDemo.Fschema

  schema "tree_paths" do
    belongs_to :parent_sch, Fschema, foreign_key: :ancestor
    belongs_to :child_sch, Fschema, foreign_key: :descendant
    field :depth, :integer
  end

  @doc false
  def changeset(tree_path, attrs) do
    tree_path
    |> cast(attrs, [])
    |> validate_required([])
  end
end
