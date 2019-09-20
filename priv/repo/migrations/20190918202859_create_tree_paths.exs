defmodule LiveViewDemo.Repo.Migrations.CreateTreePaths do
  use Ecto.Migration

  def change do
    create table(:tree_paths) do
      add :ancestor, references(:fschemas, on_delete: :delete_all), null: false
      add :descendant, references(:fschemas, on_delete: :delete_all), null: false
      add :depth, :integer, null: false, default: 0
    end

    create index(:tree_paths, [:ancestor, :descendant], unique: true)
  end
end
