defmodule Encryption.Utils do
  @key_length 32

  defp encode(d)do
    d
    |> Base.encode64()
  end

  defp decode(d)do
    d
    |> Base.decode64()
  end

  defp generate_salt_bin()do
    ExCrypto.rand_bytes!(16)
  end

  defp generate_salt_string()do
    generate_salt_bin()
    |> encode()
  end

  defp salt_string_to_bin(salt) do
    {:ok, data} = decode(salt)
    data
  end

  defp derive_pwd_key(pwd, salt) do
    KeyGenerator.generate(pwd, salt, length: 32)
      |> encode
  end

  defp derive_pwd_key(pwd)do
    salt = generate_salt_bin()
    %{salt: encode(salt), key: derive_pwd_key(pwd, salt)}
  end

  defp generate_key()do
    {:ok, aes_256_key} = ExCrypto.generate_aes_key(:aes_256, :bytes)
    aes_256_key |> encode
  end

  defp encrypt(%{key: key, payload: payload}) do
    key_size = 32
    {:ok, <<d_key::binary-size(key_size)>>} = decode(key)
    {:ok, {init_vec, cipher_text}} = ExCrypto.encrypt(d_key, payload)
    encoded = encode(init_vec <> cipher_text)
    <<byte_size(init_vec)::integer, encoded::binary>>
  end

  defp decrypt(%{key: key, payload: payload}) do
    key_size = 32
    d_key = decode_key(key, key_size)
    <<init_vec_size::integer, raw::binary>> = payload
    {:ok, <<init_vector::binary-size(init_vec_size), cipher_text::binary>>} =
    decode(raw)
    {:ok, val} = ExCrypto.decrypt(d_key, init_vector, cipher_text)
    val
  end

  defp decode_key(key, key_size) do
    {:ok, <<secret_key::binary-size(key_size)>>} = decode(key)
    secret_key
  end

  #Public API functions

  @doc """
  Takes a password and generate encrypted unique user key.
  This key can only be decrypted with the same password
  """
  def generate_key_hash(pwd)do
    #derive a key from the password
    %{key: key, salt: salt} = derive_pwd_key(pwd)

    #generate unique key
    gen_key = generate_key()

    #encrypt unique key with password derived key
    key_hash = encrypt(key, gen_key)

    #return encrypted key with the salt
    %{key_hash: salt <> "$" <> key_hash}
  end

  @doc """
  Take old password, key_hash and new password.
  Then decrypt key_hash
  """
  def update_key_hash(old_password, key_hash, new_password)do
    old_key = decrypt_key_hash(old_password, key_hash)
    %{key: key, salt: salt} = derive_pwd_key(new_password)
    key_hash = encrypt(key, old_key)
    %{key_hash: salt <> "$" <> key_hash}
  end

  def decrypt_key_hash(pwd, key_hash)do
    [salt, uk] = key_hash |> String.split("$")
    key = derive_pwd_key(pwd, salt_string_to_bin(salt))
    d_key = decrypt(key, uk)
    d_key
  end

  def decrypt(key, data)do
    decrypt(%{key: key, payload: data})
  end

  def encrypt(key, data)do
    encrypt(%{key: key, payload: data})
  end
end
