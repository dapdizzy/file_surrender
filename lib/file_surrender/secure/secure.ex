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
    # {id: 1, inserted_at: DateTime.utc_now, updated_at: DateTime.utc_now}
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
    Repo.get_by(User, uid_hash: uid_hash)
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
end
