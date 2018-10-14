defmodule Encyption.HashField do

  def hash(value) do
    :crypto.hash(:sha256, value <> get_salt(value))
  end

  defp get_salt(value) do
    secret_key_base = Application.get_env(:file_surrender, FileSurrenderWeb.Endpoint)[:secret_key_base]
    :crypto.hash(:sha256, value <> secret_key_base)
  end
end
