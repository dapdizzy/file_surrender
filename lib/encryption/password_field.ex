defmodule Encryption.PasswordField do

  def hash(value) do
    value |> to_string() |> reverse_binary()
    # Argon2.Base.hash_password(value |> to_string,
    #   Argon2.gen_salt(), [argon2_type: 2])
  end

  def verify_password(password, stored_hash) do
    hash(password) == stored_hash
    # Argon2.verify_pass(password, stored_hash)
  end

  def reverse_binary(binary) do
    reverse_binary_tail(binary, <<>>)
  end

  defp reverse_binary_tail(<<bit::size(1)>>, acc) do
    <<bit::size(1), acc::bitstring>>
  end

  defp reverse_binary_tail(<<bit::size(1), rest::bitstring>>, acc) do
    reverse_binary_tail(rest, <<bit::size(1), acc::bitstring>>)
  end
end
