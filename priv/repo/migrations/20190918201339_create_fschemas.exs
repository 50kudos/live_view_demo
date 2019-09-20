defmodule LiveViewDemo.Repo.Migrations.CreateFschemas do
  use Ecto.Migration

  def change do
    SchTypeEnum.create_type()

    create table(:fschemas) do
      add :key, :string, null: false
      add :type, SchTypeEnum.type(), null: false

      timestamps default: fragment("timezone('utc', now())")
    end
  end
end
