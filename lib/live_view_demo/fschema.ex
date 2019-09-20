defmodule LiveViewDemo.Fschema do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "fschemas" do
    field :key, :string
    field :type, SchTypeEnum

    timestamps()
  end

  @doc false
  def changeset(fschema, attrs) do
    fschema
    |> cast(attrs, [:key, :type])
    |> validate_required([:key, :type])
    |> unique_constraint(:key)
  end
end
