defmodule FileSurrender.Secure.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Encryption.EncryptedField

  require Logger

  @primary_key {:id, Encryption.HashedIdField, read_after_writes: true}
  schema "entries" do
    field :name, :binary
    field :secret, EncryptedField
    field :uid, :binary

    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    Logger.debug "entry: #{inspect entry}, attrs: #{inspect attrs}"
    cs =
      entry
      |> cast(attrs, [:uid, :name, :secret])
      |> validate_required([:uid, :name, :secret])
    case cs do
      %Ecto.Changeset{valid?: true, changes: %{uid: uid, secret: secret}} ->
        user = UsersCache.lookup(uid)
        key =
          case user do
            %{key_hash: key_hash} when key_hash |> is_binary ->
              key_hash
            _ -> raise "user with uid [#{uid}] does not have a valid key_hash. user raw: [#{inspect user}]"
          end
        import Encryption.Utils
        Logger.debug "Detected a valid changeset"
        Logger.debug "Going to encrypt the raw value of secret: #{inspect secret}"
        cs |> put_change(:secret, "$V2$_" <> encrypt(key, secret))
      _ -> cs
    end
  end

  defp prepare_fields(changeset) do
    Logger.debug "In prepare_fields, changeset: #{inspect changeset}"
    Logger.debug "changeset.data: #{inspect changeset.data}"
    if changeset.valid? do
      Logger.debug("changeset is valid and is: #{inspect changeset}")
      struct = changeset.data.__struct__
      struct.__schema__(:autogenerate_id)
      fields = struct.__schema__(:fields)
      Logger.debug("changes are: #{inspect changeset.changes}")
      changes = Enum.reduce fields, changeset.changes, fn field, acc ->
        type = struct.__schema__(:type, field)
        data = Map.get(changeset.changes, field) # || Map.get(changeset.data, field)
        Logger.debug "Field [#{field}] = #{inspect data}"
        updated_value =
          if String.contains? Atom.to_string(type), "Encryption." do
            # Logger.debug "changeset.data: #{inspect changeset.data}"
            {:ok, transformed_value} = type.dump(data)
            Logger.debug "field [#{field}] of type [#{type}], original value: #{inspect data}, transformed value: #{inspect transformed_value}"
            transformed_value
          else
            data
          end
        Map.put(acc, field, updated_value)
      end
      Logger.debug("prepared changes are: #{inspect changeset.changes}")
      %{changeset|changes: changes}
    else
      changeset
    end
  end
end
