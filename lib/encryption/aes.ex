defmodule Encryption.AES do
  @aad "AES256GCM"
  @iv_size 16

  def encrypt(plaintext) do
    IO.puts "Plaintext is: #{inspect plaintext}"
    iv = :crypto.strong_rand_bytes(@iv_size)
    key = get_key()
    IO.puts "Key: #{inspect key}"
    {ciphertext, tag} =
      :crypto.block_encrypt(:aes_gcm, key, iv, {@aad, plaintext |> to_string(), @iv_size})
    iv <> tag <> ciphertext
  end

  def decrypt(ciphertext) do
    <<iv::binary-16, tag::binary-16, ciphertext::binary>> = ciphertext
    :crypto.block_decrypt(:aes_gcm, get_key(), iv, {@aad, ciphertext, tag})
  end

  defp get_key() do
    keys = Application.get_env(:file_surrender, __MODULE__)[:keys]
    idx = keys |> Enum.count() |> Kernel.-(1)
    get_key(idx)
  end

  defp get_key(idx) do
    keys = Application.get_env(:file_surrender, __MODULE__)[:keys]
    keys |> Enum.at(idx) |> Base.decode64!
  end
end
