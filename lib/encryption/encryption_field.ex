defmodule Encryption.EncryptedField do
  alias Encryption.AES

  require Logger

  @behaviour Ecto.Type

  def type, do: :binary

  def cast(value) do
    Logger.debug("casting value [#{inspect value}]")
    {:ok, to_string(value)}
  end

  def dump(value) do
    Logger.debug "No dumping required, encryption is done in the changeset transformation."
    {:ok, value}
    # Logger.debug("dumping value [#{inspect value}]")
    # ciphertext = value |> to_string |> AES.encrypt
    # {:ok, ciphertext}
  end

  def load("$V2$_" <> _value = value) do
    Logger.debug "V2 type value detected. No loading transformation is required, it will be later done in the view."
    # decrypt(user.id |> decrypt_key_hash(key), secret)
    {:ok, value}
  end

  def load("$V3$_" <> _value = secret) do
    Logger.debug("V3 type value detected. No loading transformation is required. Decryption will take place in the view.")
    {:ok, secret}
  end

  def load("Editing" <> _tail = value) do
    {:ok, value}
  end

  def load(value) do
    Logger.debug("loading (oldfashioned) value [#{inspect value}]")
    {:ok, AES.decrypt(value)}
  end

end
