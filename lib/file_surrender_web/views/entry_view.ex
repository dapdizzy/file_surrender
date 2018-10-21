defmodule FileSurrenderWeb.EntryView do
  use FileSurrenderWeb, :view

  require Logger

  def decrypt_value(_uid, secret) do
    Logger.debug "Old-fashioned value detected, no decryption in view needed."
    secret
  end

  def decrypt_value(uid, "$V2$_" <> _secret = secret) do
    Logger.debug "decrypting V2 value in view"
    user = UsersCache.lookup(uid)
    key =
      case user do
        %{key_hash: key_hash} when key_hash |> is_binary -> key_hash
        _ -> raise "user with uid [#{uid}] does not have a valid key_hash field. Raw user is [#{inspect user}]"
      end
    import Encryption.Utils
    decrypt(key, secret) <> " (V2 value)" # TODO: remove after testing
  end
end
