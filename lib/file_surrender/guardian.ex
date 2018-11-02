defmodule FileSurrender.Guardian do
  use Guardian, otp_app: :file_surrender

  require Logger

  def subject_for_token(resource, _claims) do
    subject = resource.id
    UsersCache.add(resource)
    {:ok, subject}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    case UsersCache.lookup(id) do
      %{} = user -> {:ok, user}
      nil ->
        Logger.debug("Got empty user [nil] from UsersCache lookup by id [#{id}] obtained from the claims[sub].")
        {:error, :user_id_not_found_in_cache}
    end
  end
end
