defmodule FileSurrender.Guardian do
  use Guardian, otp_app: :file_surrender

  def subject_for_token(resource, _claims) do
    subject = resource.id
    UsersCache.add(resource)
    {:ok, subject}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    user = UsersCache.get!(id)
    {:ok, user}
  end
end
