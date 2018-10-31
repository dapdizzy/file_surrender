defmodule FileSurrenderWeb.EntryView do
  use FileSurrenderWeb, :view

  alias Encryption.UserContext

  require Logger

  def decrypt_value(user_id, "$V2$_" <> secret = value) do
    Logger.debug "decrypting V2 value in view: [#{inspect value}]"
    key = UserContext.get_user_key(user_id)
    import Encryption.Utils
    decrypt(user_id, key, secret) <> " (V2 value)" # TODO: remove after testing
  end

  def decrypt_value(_uid, secret) do
    Logger.debug "Old-fashioned value detected [#{inspect secret}], no decryption in view needed."
    secret
  end
end
