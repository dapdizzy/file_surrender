defmodule Encryption.HashedField do
  @behaviour Ecto.Type

  require Logger

  def type, do: :binary

  def cast(value) do
    {:ok, to_string(value)}
  end

  def dump(value) do
    Logger.debug "Dumping hashed value [#{inspect value}]"
    {:ok, hash(value)}
  end

  def load(value) do
    {:ok, value}
  end

  def verify_secret(open_secret, secret) do
    Argon2.verify_hash(open_secret, secret)
  end

  defp get_salt() do
    System.get_env("salt64") |> Base.decode64!
  end

  defp hash(value) do
    salt = get_salt()
    Argon2.Base.hash_password(value, salt, argon2_type: 1, format: :raw_hash)
  end

end
