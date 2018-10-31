defmodule Encryption.UserContext do
  def get_user_key(user_id) do
    user = UsersCache.get!(user_id)
    case user do
      %{key_hash: key_hash} when key_hash |> is_binary -> key_hash
      _ -> raise "user with uid [#{user.uid}] does not have a valid key_hash field. Raw user is [#{inspect user}]"
    end
  end
end
