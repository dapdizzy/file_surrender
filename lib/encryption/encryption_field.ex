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
    Logger.debug "V2 type value detected. No loading transformation is required thus."
    {:ok, value}
  end

  def load(value) do
    Logger.debug("loading (oldfashioned) value [#{inspect value}]")
    {:ok, AES.decrypt(value)}
  end

end
