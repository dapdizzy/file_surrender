defmodule FileSurrender.Secure.Secret do
  use Ecto.Schema
  import Ecto.Changeset
  import Encryption.HashedField, only: [verify_secret: 2]
  alias Encryption.HashedField
  alias FileSurrender.Secure.User

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

  defp verify_open_secret(%Ecto.Changeset{valid? : false} = changeset) do
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

  defp copy_new_secret(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end

  defp copy_new_secret(%Ecto.Changeset{valid?: true, changes: %{new_secret: new_secret}} = changeset) do
    changeset |> put_change(:secret, new_secret)
  end
end
