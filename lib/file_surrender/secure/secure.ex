defmodule FileSurrender.Secure do
  @moduledoc """
  The Secure context.
  """

  import Ecto.Query, warn: false
  alias FileSurrender.Repo

  alias FileSurrender.Secure.Entry

  require Logger

  @doc """
  Returns the list of entries.

  ## Examples

      iex> list_entries()
      [%Entry{}, ...]

  """
  def list_entries(uid, probe \\ false) do
    Logger.debug("listing entries for uid #{uid}")
    query = (from e in Entry, where: e.uid == ^uid)
      |> conditional(probe, & &1 |> limit(1))
    Repo.all(query)
  end

  @doc """
  Determines whether the user has related entries by uid.
  """
  def has_entries_by_uid(uid) do
    case list_entries(uid, true) do
      [] -> false
      list when list |> is_list -> true
    end
  end

  @doc """
  Lists entries by internal database id of the parent User record.
  """
  def list_entries_by_id(id, probe \\ false) do
    Logger.debug("Listing entries for the user.id = #{id}")
    query = (from e in Entry, where: e.user_id == ^id)
      |> conditional(probe, & &1 |> limit(1))
    Repo.all(query)
  end

  def has_secure_entries?(id) do
    Logger.debug("Determine whether the user (#{id}) has any secure entries.")
    query = (from e in Entry, where: e.user_id == ^id and like(e.secret, "$V3$_%"), limit: 1)
    Repo.one(query) != nil
  end

  def has_only_secure_entries?(id) do
    Logger.debug("Querying whether the user (#{id}) has only secure encrypted entries or has none.")
    query = (from e in Entry, where: e.user_id == ^id and not like(e.secret, "$V3$_%"), limit: 1)
    Repo.one(query) == nil
  end

  @doc """
  Denotes whether there are any entries related to user.internal_id
  """
  def has_entries?(internal_user_id) do
    list_entries_by_id(internal_user_id, true)
  end

  defp conditional(query, condition, adorner) do
    if condition do
      query |> adorner.()
    else
      query
    end
  end

  @doc """
  Rewires the related entries from uid field to internal_id field, as uid relation is considered to be obsolete in the new schema.
  """
  def rewire_entries(uid, internal_id) do
    from(e in Entry, where: e.uid == ^uid)
      |> Repo.update_all(set: [user_id: internal_id, uid: ""])
  end

  @doc """
  Gets a single entry.

  Raises `Ecto.NoResultsError` if the Entry does not exist.

  ## Examples

      iex> get_entry!(123)
      %Entry{}

      iex> get_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_entry!(id), do: Repo.get!(Entry, id)

  @doc """
  Gets the entry by id in a safe way, i.e., does not raise when entry is not found.
  """
  def get_entry(id), do: Repo.get(Entry, id)

  @doc """
  Creates a entry.

  ## Examples

      iex> create_entry(%{field: value})
      {:ok, %Entry{}}

      iex> create_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_entry(attrs \\ %{}) do
    Logger.debug("Secure.create_entry, attrs: #{inspect attrs}")
    %Entry{}
    |> Entry.changeset(attrs, true)
    |> Repo.insert()
  end

  @doc """
  Updates a entry.

  ## Examples

      iex> update_entry(entry, %{field: new_value})
      {:ok, %Entry{}}

      iex> update_entry(entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_entry(%Entry{} = entry, attrs) do
    entry
    |> Entry.changeset(attrs, true)
    |> Repo.update()
  end

  @doc """
  Deletes a Entry.

  ## Examples

      iex> delete_entry(entry)
      {:ok, %Entry{}}

      iex> delete_entry(entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_entry(%Entry{} = entry) do
    Repo.delete(entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking entry changes.

  ## Examples

      iex> change_entry(entry)
      %Ecto.Changeset{source: %Entry{}}

  """
  def change_entry(%Entry{} = entry) do
    Entry.changeset(entry, %{}, false)
  end

  alias FileSurrender.Secure.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets the user by uid_hash which is a unique key.
  """
  def get_user_by_uid_hash(uid_hash) do
    query = (from u in User, where: u.uid_hash == ^uid_hash, preload: [:secret])
    Repo.one(query)
    # TODO: need to verify this change.
    # Repo.get_by(User, uid_hash: uid_hash)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  alias FileSurrender.Secure.Secret

  @doc """
  Returns the list of secrets.

  ## Examples

      iex> list_secrets()
      [%Secret{}, ...]

  """
  def list_secrets do
    Repo.all(Secret)
  end

  @doc """
  Gets a single secret.

  Raises `Ecto.NoResultsError` if the Secret does not exist.

  ## Examples

      iex> get_secret!(123)
      %Secret{}

      iex> get_secret!(456)
      ** (Ecto.NoResultsError)

  """
  def get_secret!(id), do: Repo.get!(Secret, id)

  @doc """
  Gets the Secret by user_id.
  """
  def get_user_secret(user_id) do
    Repo.get_by(Secret, user_id: user_id)
  end

  @doc """
  Determines whether the user has personal secret stored.
  """
  def has_secret(user_id) do
    false
    # TODO: may be the whole function is not needed...
  end

  @doc """
  Creates a secret.

  ## Examples

      iex> create_secret(%{field: value})
      {:ok, %Secret{}}

      iex> create_secret(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_secret(attrs \\ %{}, user_id) do
    %Secret{user_id: user_id}
    |> Secret.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a secret.

  ## Examples

      iex> update_secret(secret, %{field: new_value})
      {:ok, %Secret{}}

      iex> update_secret(secret, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_secret(%Secret{} = secret, attrs) do
    secret
    |> Secret.changeset(attrs, true)
    |> Repo.update()
  end

  def set_secret_key_hash(%Secret{key_hash: key_hash, verified?: true, open_secret: open_secret} = secret)
  when (key_hash == nil or key_hash == "")
  and open_secret |> is_binary() and open_secret != ""
  do
    Secret.set_key_hash_changeset(secret)
    |> Repo.update!()
  end

  def set_secret_key_hash(%Secret{} = secret) do
    secret
  end

  @doc """
  Deletes a Secret.

  ## Examples

      iex> delete_secret(secret)
      {:ok, %Secret{}}

      iex> delete_secret(secret)
      {:error, %Ecto.Changeset{}}

  """
  def delete_secret(%Secret{} = secret) do
    Repo.delete(secret)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking secret changes.

  ## Examples

      iex> change_secret(secret)
      %Ecto.Changeset{source: %Secret{}}

  """
  def change_secret(%Secret{} = secret) do
    Secret.changeset(secret, %{})
  end

  defp decrypt(secret, key_hash, encryption_secret) do
    Encryption.Utils.decrypt(encryption_secret, key_hash, secret)
  end

  defp encrypt(secret, key_hash, encryption_secret) do
    Encryption.Utils.encrypt(encryption_secret, key_hash, secret)
  end

  def reencrypt_entries(user_id, key_hash, old_secret, new_secret) do
    query = from(e in Entry, where: e.user_id == ^user_id)
    stream = Repo.stream(query)
    Repo.transaction(fn ->
      stream
      |> Stream.map(fn %Entry{secret: secret} = entry ->
        case secret do
          "$V3$_" <> secret_part ->
            updated_secret = "$V3$_" <> (secret_part |> decrypt(key_hash, old_secret) |> encrypt(key_hash, new_secret))
            Ecto.Changeset.change(entry, secret: updated_secret)
          _ -> nil
        end
      end)
      |> Stream.filter(fn %Ecto.Changeset{} -> true; nil -> false end)
      |> Stream.map(fn %Ecto.Changeset{} = changeset ->
        case Repo.update(changeset) do
          {:ok, _updated} -> :ok
          {:error, changeset} -> raise "Something went wrong with the changeset: [#{inspect changeset}]"
        end
      end)
      |> Enum.count
    end)
    |> case do
      {:ok, counter} -> counter
      {:error, error} -> raise "An error occured inside reencryption transaction: [#{inspect error}]"
    end
  end
end
