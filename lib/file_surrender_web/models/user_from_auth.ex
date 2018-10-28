defmodule UserFromAuth do
  require Logger
  require Poison

  alias Ueberauth.Auth
  alias FileSurrender.Secure
  alias FileSurrender.Secure.User

  def find_or_create(%Auth{} = auth) do
    basic_info = basic_info(auth) |> add_hashed_id
    %User{id: id, key_hash: key_hash} = get_user_by_hash(basic_info)
    {:ok, basic_info |> Map.put(:key_hash, key_hash) |> Map.put(:internal_id, id)}
  end

  defp get_user_by_hash(%{hashed_id: hashed_id} = basic_info) do
    case Secure.get_user_by_uid_hash(hashed_id) do
      %User{} = u -> u
      nil -> create_new_user(basic_info)
    end
  end

  defp create_new_user(%{hashed_id: hashed_id} = basic_info) do
    gen_key_hash = gen_key_hash(basic_info)
    Secure.create_user(%{uid_hash: hashed_id, key_hash: gen_key_hash})
  end

  defp add_hashed_id(%{id: id} = info) do
    info |> Map.put(:hashed_id, hash(id))
  end

  defp get_salt() do
    System.get_env("salt64") |> Base.decode64!
  end

  defp hash(value) do
    salt = get_salt()
    Argon2.Base.hash_password(value, salt, argon2_type: 1, format: :raw_hash)
  end

  # github does it this way
  defp avatar_from_auth( %{info: %{urls: %{avatar_url: image}} }), do: image

  #facebook does it this way
  defp avatar_from_auth( %{info: %{image: image} }), do: image

  # default case if nothing matches
  defp avatar_from_auth( auth ) do
    Logger.warn auth.provider <> " needs to find an avatar URL!"
    Logger.debug(Poison.encode!(auth))
    nil
  end

  # defp code_from_auth(%{}) do
  #
  # defp code_from_auth(auth) do
  #   Logger.warn auth.provider <> " does not have code!"
  #   auth |> Poison.encode! |> Logger.debug
  #   nil
  # end

  defp basic_info(auth) do
    %{id: auth.uid || auth.extra.raw_info.user["id"] |> to_string(), name: name_from_auth(auth), avatar: avatar_from_auth(auth)}
  end

  defp name_from_auth(auth) do
    if auth.info.name do
      auth.info.name
    else
      name = [auth.info.first_name, auth.info.last_name]
      |> Enum.filter(&(&1 != nil and &1 != ""))

      cond do
        length(name) == 0 -> auth.info.nickname
        true -> Enum.join(name, " ")
      end
    end
  end

  import Encryption.Utils

  defp gen_key_hash(info) do
    %{key_hash: key_hash} = generate_key_hash(info.id)
    key_hash
  end
end
