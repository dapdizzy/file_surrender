defmodule Encryption.HashedIdField do
  @behaviour Ecto.Type
  @hashids Hashids.new(min_len: 8, salt: "id salt")
  @moduledoc """
  Converts integers to Hashids.

  See http://hashids.org/ for more information.
  """

  def type(), do: :id

  def cast(term) when is_integer(term), do: {:ok, Hashids.encode(@hashids, term)}
  def cast(term) when is_binary(term),  do: dump(term)
  def cast(_), do: :error

  def dump(term) when is_binary(term) do
   Hashids.decode!(@hashids, term)
   |> case do
     [int] -> {:ok, int}
     _ -> :error
   end
  end
  def dump(term) when is_integer(term), do: {:ok, term}
  def dump(_), do: :error

  def load(term) when is_integer(term), do: cast(term)
  def load(_), do: :error
end
