defmodule FileSurrender.Secure.Secret do
  use Ecto.Schema
  import Ecto.Changeset
  import Encryption.HashedField, only: [verify_secret: 2]
  alias Encryption.HashedField
  alias FileSurrender.Secure.User
  alias FileSurrender.Secure.Secret

  require Logger

  schema "secrets" do
    field :open_secret, :string, virtual: true
    field :new_secret, :string, virtual: true
    field :secret, HashedField, read_after_writes: true
    field :verified?, :boolean, virtual: true, default: false
    field :key_hash, :string
    # field :user_id, :id
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(secret, attrs, update \\ false) do
    fields = get_fields(update)
    secret
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> verify_open_secret()
    |> copy_open_secret()
    |> copy_new_secret()
    |> set_key_hash()
  end

  defp get_fields(false) do
    [:open_secret]
  end

  defp get_fields(true) do
    [:open_secret, :new_secret]
  end

  defp verify_open_secret(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end

  defp verify_open_secret(%Ecto.Changeset{valid?: true, changes: %{open_secret: open_secret}, data: %Secret{secret: secret}} = changeset) when secret |> is_binary() and secret != "" do
    unless verify_secret(open_secret, secret) do
      changeset
      |> add_error(:open_secret, "The secret value does not match the stored secret.")
    else
      changeset
    end
  end

  defp verify_open_secret(%Ecto.Changeset{valid?: true, changes: changes, data: %Secret{verified?: true, secret: secret, open_secret: open_secret}} = changeset)
  when secret |> is_binary() and secret != ""
  and open_secret |> is_binary() and open_secret != ""
  do
    unless verify_secret(open_secret, secret) do
      changeset
      |> add_error(:open_secret, "The secret value does not match the stored secret.")
    else
      changeset
    end
  end

  # Passthrough in all the other cases (like if according fields are not present in changes or data is missing, i.e., whatever)
  defp verify_open_secret(%Ecto.Changeset{} = changeset) do
    changeset
  end

  defp copy_open_secret(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end

  defp copy_open_secret(%Ecto.Changeset{valid?: true, changes: %{open_secret: open_secret}} = changeset) when open_secret |> is_binary() and open_secret != "" do
    changeset |> put_change(:secret, open_secret)
  end

  defp copy_open_secret(%Ecto.Changeset{} = changeset) do
    changeset
  end

  defp copy_new_secret(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end

  defp copy_new_secret(%Ecto.Changeset{valid?: true, changes: %{new_secret: new_secret}} = changeset) when new_secret |> is_binary() and new_secret != "" do
    changeset |> put_change(:secret, new_secret)
  end

  defp copy_new_secret(%Ecto.Changeset{} = changeset) do
    changeset # Passthough in all the other cases.
  end

  def set_key_hash(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end

  def set_key_hash(%Ecto.Changeset{valid?: true, changes: %{open_secret: open_secret}, data: %Secret{secret: secret}} = changeset) when secret == nil or secret == "" do
    #  This only works for the case when we create secret, i.e., have open_secret in changes and do not have secret value filled in data struct.
    key_hash = gen_key_hash(open_secret)
    changeset |> put_change(:key_hash, key_hash)
  end

  def set_key_hash(%Ecto.Changeset{valid?: true, changes: changes, data: %Secret{open_secret: open_secret, verified?: true}} = changeset) do
    if changes |> Map.equal?(%{}) do
      changeset |> put_change(:key_hash, gen_key_hash(open_secret))
      Logger.debug("Key_hash has been put to the user's secret!")
    else
      changeset
    end
  end

  def set_key_hash(%Ecto.Changeset{} = changeset) do
    changeset
  end

  def set_key_hash_changeset(secret) do
    Ecto.Changeset.change(secret, %{})
    |> verify_open_secret()
    |> set_key_hash()
  end

  def secret_verified?(nil) do
    false
  end

  def secret_verified?(%Secret{verified?: verified}) do
    verified
  end

  def has_secret?(boolean, nil) do
    !boolean
  end

  def has_secret?(boolean, %Secret{secret: secret}) do
    has_secret = secret && secret != ""
    if boolean, do: has_secret, else: !has_secret
  end

  # Need thowse two due to limitations on the types of values (fucntions in particular) we can use in plugs.

  def has_secret?(secret) do
    has_secret?(true, secret)
  end

  def has_no_secret?(secret) do
    has_secret?(false, secret)
  end

  defp gen_key_hash(open_secret) do
    %{key_hash: key_hash} = Encryption.Utils.generate_key_hash(open_secret)
    key_hash
  end
end
