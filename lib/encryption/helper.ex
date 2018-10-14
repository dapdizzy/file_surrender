defmodule Encryption.Helper do
  def get_encryption_keys() do
    System.get_env("ENCRYPTION_KEYS") || raise "ENCRYPTION_KEYS environment variable is not set"
  end
end

# extra: %Ueberauth.Auth.Extra
# {raw_info: %
# {token: %OAuth2.AccessToken
# {access_token: "78bd6ad07a0cbfe802a95a3b6007495a08a2448e6a4ab25c7403d5d25df54a27526117ff72c13014862c8",
# expires_at: 1539605691,
# other_params: %{"user_id" => 1418001},
# refresh_token: nil, token_type: "Bearer"},
# user: %{"first_name" => "Дмитрий", "id" => 1418001,
# "last_name" => "Пятков"}}}, info: %Ueberauth.Auth.Info{description: nil, email: nil, first_name: "Дмитрий", image: nil, last_name: "Пятков", location: nil, name: "Дмитрий Пятков", nickname: nil, phone: nil, urls: %{vk: "https://vk.com/id"}}, provider: :vk, strategy: Ueberauth.Strategy.VK, uid: nil}
