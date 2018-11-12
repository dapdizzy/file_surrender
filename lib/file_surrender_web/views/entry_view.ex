defmodule FileSurrenderWeb.EntryView do
  use FileSurrenderWeb, :view

  alias Encryption.UserContext

  require Logger

  def decrypt_value(user_id, "$V2$_" <> secret = value) do
    Logger.debug "decrypting V2 value in view: [#{inspect value}]"
    %{key_hash: key_hash, id: id} = UsersCache.get!(user_id)
    import Encryption.Utils
    decrypt(id, key_hash, secret) <> " (V2 value)" # TODO: remove after testing
  end

  def decrypt_value(user_id, "$V3$_" <> secret = value) do
    Logger.debug("decrypting V3 (secret encrypted) value in view: [#{inspect value}]")
    %{key_hash: key_hash, secret: %Secret{verified?: true, open_secret: encryption_secret}} = UsersCache.get!get!(user_id)
    import Encryption.Utils, only: [decrypt: 3]
    decrypt(encryption_secret, key_hash, secret) <> " (V3 Secret encrypted value)"
  end

  def decrypt_value(_uid, secret) do
    Logger.debug "Old-fashioned value detected [#{inspect secret}], no decryption in view needed."
    secret
  end
end
