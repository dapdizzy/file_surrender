defmodule FileSurrender.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Encryption.PasswordField
  alias Encryption.EncryptedField


  schema "entries" do
    field :name, :binary
    field :secret, EncryptedField
    field :uid, :binary

    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:uid, :name, :secret])
    |> validate_required([:uid, :name, :secret])
    |> prepare_fields
  end

  defp prepare_fields(changeset) do
    if changeset.valid? do
      struct = changeset.__struct__
      fields = struct.__schema__(:fields)
      changes = Enum.reduce fields, %{}, fn field, acc ->
        type = struct.__schema__(field)
        if String.contains? Atom.to_string(type), "Encryption." do
          data = Map.get(changeset.data, "#{type}")
          {:ok, transformed_value} = type.dump(data)
          Map.put(acc, field, transformed_value)
        else
          acc
        end
      end
      %{changeset|changes: changes}
    else
      changeset
    end
  end
end
