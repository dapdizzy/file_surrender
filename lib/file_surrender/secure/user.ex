defmodule FileSurrender.Secure.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Encryption.HashedField
  alias FileSurrender.Secure.Entry

  # @primary_key {:uid_hash, :string, read_after_writes: true}

  schema "users" do
    field :uid_hash, :string
    field :key_hash, :string
    has_many :entries, Entry

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:uid_hash, :key_hash])
    |> validate_required([:uid_hash, :key_hash])
    |> unique_constraint(:uid_hash)
  end
end
