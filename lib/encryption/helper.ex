defmodule Encryption.Helper do
  def get_encryption_keys() do
    System.get_env("ENCRYPTION_KEYS") || raise "ENCRYPTION_KEYS environment variable is not set"
  end
end
