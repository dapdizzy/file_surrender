defmodule FileSurrender.Guardian do
  use Guardian, otp_app: :file_surrender

  def subject_for_token(resource, _claims) do
    subject = resource.id
    UsersCache.add(resource)
    {:ok, subject}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    case UsersCache.lookup(id) do
      %{} = user -> {:ok, user}
      nil -> {:error, :user_id_not_found_in_cache}
    end
  end
end
