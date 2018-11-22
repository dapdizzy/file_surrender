defmodule FileSurrender.Secure.Secret do
  use Ecto.Schema
  import Ecto.Changeset
  import Encryption.HashedField, only: [verify_secret: 2]
  alias Encryption.HashedField
  alias FileSurrender.Secure.User
  alias FileSurrender.Secure.Secret

  schema "secrets" do
    field :open_secret, :string, virtual: true
    field :new_secret, :string, virtual: true
    field :secret, HashedField
    field :verified?, :boolean, virtual: true, default: false
    # field :user_id, :id
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(secret, attrs) do
    secret
    |> cast(attrs, [:open_secret, :new_secret])
    |> validate_required([:open_secret, :new_secret])
    |> verify_open_secret()
    |> copy_new_secret()
  end

  defp verify_open_secret(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end

  defp verify_open_secret(%Ecto.Changeset{valid?: true, changes: %{open_secret: open_secret}, data: %Secret{secret: secret}} = changeset) do
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

  defp copy_new_secret(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end

  defp copy_new_secret(%Ecto.Changeset{valid?: true, changes: %{new_secret: new_secret}} = changeset) do
    changeset |> put_change(:secret, new_secret)
  end

  defp copy_new_secret(%Ecto.Changeset{} = changeset) do
    changeset # Passthough in all the other cases.
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
end
