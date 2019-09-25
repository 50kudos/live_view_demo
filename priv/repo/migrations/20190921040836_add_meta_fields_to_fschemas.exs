defmodule LiveViewDemo.Repo.Migrations.AddMetaFieldsToFschemas do
  use Ecto.Migration

  def change do
    alter table(:fschemas) do
      add :title, :string
      add :description, :string
      add :ui, :map
      add :assert, :map
    end
  end
end
