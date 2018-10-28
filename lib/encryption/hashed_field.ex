defmodule Encryption.HashedField do
  alias Encryption.AES

  @behaviour Ecto.Type

  require Logger

  def type, do: :binary

  def cast(value) do
    {:ok, to_string(value)}
  end

  def dump(value) do
    Logger.debug "Dumping hashed value [#{inspect value}]"
    {:ok, Argon2.hash_pwd_salt(value)}
  end

  def load(value) do
    {:ok, value}
  end

end
