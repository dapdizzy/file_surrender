defmodule FileSurrenderWeb.EntryView do
  use FileSurrenderWeb, :view

  require Logger

  def decrypt_value(user_id, "$V2$_" <> secret = _secret) do
    Logger.debug "decrypting V2 value in view"
    user = UsersCache.lookup(user_id)
    key =
      case user do
        %{key_hash: key_hash} when key_hash |> is_binary -> key_hash
        _ -> raise "user with uid [#{user.uid}] does not have a valid key_hash field. Raw user is [#{inspect user}]"
      end
    import Encryption.Utils
    decrypt(user.id |> decrypt_key_hash(key), secret) <> " (V2 value)" # TODO: remove after testing
  end

  def decrypt_value(_uid, secret) do
    Logger.debug "Old-fashioned value detected, no decryption in view needed as it should have already been done on the type load transformation."
    secret
  end
end
