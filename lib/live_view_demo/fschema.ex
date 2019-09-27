defmodule LiveViewDemo.Fschema do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "fschemas" do
    field :key, :string
    field :type, SchTypeEnum
    field :title, :string
    field :description, :string

    embeds_one :assert, Assert do
      field :maxLength, :integer
      field :minLength, :integer
      field :pattern, :string, default: ""

      field :maximum, :integer
      field :minimum, :integer
    end

    timestamps()
  end

  @doc false
  def changeset(fschema, attrs \\ %{}) do
    fschema
    |> cast(attrs, [:key, :type, :title, :description])
    |> cast_embed(:assert, with: &assert_changeset/2)
    |> validate_required([:key, :type])
    |> unique_constraint(:key)
  end

  defp assert_changeset(assert, attrs \\ %{}) do
    assert
    |> cast(attrs, [:maxLength, :minLength, :pattern, :maximum, :minimum])
  end
end
