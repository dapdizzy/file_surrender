defmodule FileSurrenderWeb.PageView do
  use FileSurrenderWeb, :view

  alias FileSurrender.Secure.Secret

  def secret_required?(nil) do
    true
  end

  def secret_required?(%Secret{}) do
    false
  end

  def verification_required?(nil) do
    false
  end

  def verification_required?(%Secret{verified?: verified}) do
    !verified
  end
end
