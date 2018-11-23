defmodule FileSurrenderWeb.SecretView do
  use FileSurrenderWeb, :view

  alias FileSurrender.Secure.Secret

  def display_secret(nil), do: "(You do not have Secret value yet)"

  def display_secret(%Secret{secret: secret, open_secret: open_secret, verified?: verified, key_hash: key_hash}) do
    unless verified do
      "(You need to verify your Secret value)"
    else
      s = secret |> String.slice(0, 10)
      s <> "..." <> (open_secret |> String.slice(0, 10)) <> ".." <> "[key_hash: #{String.slice(key_hash, 0, 10)}...]"
    end
  end

  def verified?(nil) do
    false
  end

  def verified?(%Secret{verified?: verified}) do
    verified
  end

  def has_secret?(nil) do
    false
  end

  def has_secret?(%Secret{secret: secret}) do
    !empty?(secret)
  end

  defp empty?(nil) do
    true
  end

  defp empty?("") do
    true
  end

  defp empty?(string) when string |> is_binary() do
    false
  end
end
