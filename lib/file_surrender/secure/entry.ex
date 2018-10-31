defmodule FileSurrender.Secure.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Encryption.EncryptedField
  alias FileSurrender.Secure.User
  alias FileSurrender.Secure.Entry

  require Logger

  @primary_key {:id, Encryption.HashedIdField, read_after_writes: true}
  schema "entries" do
    field :name, :binary
    field :secret, EncryptedField
    field :uid, :binary
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(entry, attrs, true) do
    Logger.debug "entry: #{inspect entry}, attrs: #{inspect attrs}"
    entry
      |> cast(attrs, [:user_id, :name, :secret])
      |> validate_required([:user_id, :name, :secret])
      |> encrypt_changeset(entry.user_id)
  end

  # A clause not intended for update, rather for new entry creation in a form.
  def changeset(entry, attrs, false) do
    Logger.debug "entry: #{inspect entry}, attrs: #{inspect attrs}"
    entry
      |> cast(attrs, [:user_id, :name, :secret])
      |> validate_required([:user_id, :name, :secret])
  end

  # Consider if it is a valid changeset holding a secret field change.
  defp encrypt_changeset(%Ecto.Changeset{valid?: true, changes: %{secret: secret} = changes} = cs, user_id) do
    Logger.debug("Valid entry changeset with secret update")
    {uid, key} =
      case UsersCache.get!(user_id || changes.user_id) do
        %{id: id, key_hash: key_hash} -> {id, key_hash}
        weird_user -> raise "Weird user returned from cache: [#{inspect weird_user}]"
      end
    import Encryption.Utils
    Logger.debug "Going to encrypt the raw value of secret: #{inspect secret}"
    cs |> put_change(:secret, "$V2$_" <> encrypt(uid, key, secret))
  end

  # Passthrough in any other case.
  defp encrypt_changeset(%Ecto.Changeset{} = changeset, _user_id) do
    Logger.debug("encrypt_changeset: Passing through changeset")
    changeset
  end

  @doc """
  Decrypts entry's secret value.
  """
  def decrypt_entry(%Entry{secret: "$V2$_" <> secret, user_id: user_id} = entry) do
    %{id: id, key_hash: key_hash} = UsersCache.get!(user_id)
    import Encryption.Utils
    %{entry|secret: decrypt(id, key_hash, secret)}
  end

  # Passthrough if the entry's secret is not of V2 pattern
  def decrypt_entry(%Entry{} = entry), do: entry

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
