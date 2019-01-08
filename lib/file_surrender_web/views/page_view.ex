defmodule FileSurrenderWeb.PageView do
  use FileSurrenderWeb, :view

  alias FileSurrender.Secure.Secret

  def secret_required?(%Secret{}) do
    false
  end

  def secret_required?(_) do
    true
  end

  def verification_required?(%Secret{verified?: verified}) do
    !verified
  end

  def verification_required?(_) do
    false
  end
end
