defmodule UsersCache do
  use Agent

  def start_link() do
    Agent.start_link(fn -> %{} end, name: UsersCache)
  end

  def add(user) do
    UsersCache |> Agent.update(fn map ->
      map
        |> Map.put(user.id, user)
        # Have the user mapped twice for convenient access from Entry.changeset where we have user_id now.
        |> Map.put(user.internal_id, user)
    end)
  end

  def lookup(user_id) do
    UsersCache |> Agent.get(fn map -> map[user_id] end)
  end
end
