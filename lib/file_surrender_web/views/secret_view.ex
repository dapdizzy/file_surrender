defmodule FileSurrenderWeb.SecretView do
  use FileSurrenderWeb, :view

  alias FileSurrender.Secure.Secret

  def display_secret(nil), do: "(You do not have Secret value yet)"

  def display_secret(%Secret{secret: secret, open_secret: open_secret}) do
    unless open_secret |> empty? do
      "(You need to verify your Secret value)"
    else
      s = secret |> String.slice(0, 10)
      s <> "..."
    end
  end

  def verified?(nil) do
    false
  end

  def verified?(%Secret{verified?: verified}) do
    verified
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
