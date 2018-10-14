defmodule UsersCache do
  use Agent

  def start_link() do
    Agent.start_link(fn -> %{} end, name: UsersCache)
  end

  def add(user) do
    UsersCache |> Agent.update(fn map -> map |> Map.put(user.id, user) end)
  end

  def lookup(user_id) do
    UsersCache |> Agent.get(fn map -> map[user_id] end)
  end
end
