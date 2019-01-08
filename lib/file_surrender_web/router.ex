defmodule FileSurrenderWeb.Router do
  use FileSurrenderWeb, :router

  require Ueberauth
  require Logger

  alias FileSurrender.Secure.Secret

  defp redirect_to_unauthorized_path(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp redirect_to_unauthorized_path(conn, _options) do
    path = get_session(conn, :unauthorized_path)
    user = Guardian.Plug.current_resource(conn)
    if path && user do
      Logger.debug("A case with a captured unauthorized_path and a valid user (authorized) detected.")
      Logger.debug("Redirecting to [#{path}]")
      conn
      |> delete_session(:unauthorized_path)
      |> put_flash(:info, "Taking you back to where you've headed.")
      |> redirect(to: path)
      |> halt
    else
      conn
    end
  end

  defp redirect_to_unverified_secret_path(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp redirect_to_unverified_secret_path(conn, _options) do
    secret_path = get_session(conn, :unverified_secret_path)
    user = Guardian.Plug.current_resource(conn)
    if secret_path && user do
      case user do
        %{secret: %Secret{verified?: true}} ->
          conn
          |> put_flash(:info, "Taking you back to Secret resource.")
          |> delete_session(:unverified_secret_path)
          |> redirect(to: secret_path)
          |> halt
        _ -> conn
      end
    else
      conn
    end
  end

  defp secret_path(conn, function) do
    FileSurrenderWeb.SecretController.secret_path_export(conn, function)
  end

  defp process_last_redirected_path(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp process_last_redirected_path(conn, _options) do
    case conn |> get_session(:last_redirected_path) do
      nil -> conn
      path ->
        if path != current_path(conn) and path in [secret_path(conn, :new), secret_path(conn, :verify_prompt)] do
          Logger.debug("Skipping redirection back from a redirected url")
          conn
          |> put_flash(:info, "If you wanna go back. we're taking you there, no problem.")
          |> delete_session(:last_redirected_path)
          |> assign(:skip_redirection, true)
        else
          conn
        end
    end
  end

  defp redirect_to_secret_entry_or_verification(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp redirect_to_secret_entry_or_verification(conn, _options) do
    user = Guardian.Plug.current_resource(conn)
    case user do
      %{secret: secret} ->
        needs_redirection = !Secret.secret_verified?(secret)
        conn =
          if !needs_redirection do
            conn |> put_flash(:info, nil)
          else
            conn
          end
        process_user_with_no_or_secure_only_entries(conn, needs_redirection && !conn.assigns[:skip_redirection], user)
      nil ->
        conn
    end
  end

  defp process_user_with_no_or_secure_only_entries(conn, false, _user) do
    conn
  end

  defp process_user_with_no_or_secure_only_entries(conn, true, user) do
    process_no_secret_redirection(conn, user.secret)
  end

  defp process_no_secret_redirection(conn, secret) do
    prev_path = conn |> get_session(:prev_path)
    unless (prev_path in [secret_path(conn, :new), secret_path(conn, :verify_prompt)])
    or (current_path(conn) in [secret_path(conn, :new), secret_path(conn, :verify_prompt)]) do
      redirection_path = redirection_path(conn, secret)
      conn
      |> put_flash(:info, redirection_message(secret))
      |> put_session(:last_redirected_path, redirection_path)
      |> put_session(:prev_path, current_path(conn))
      |> redirect(to: redirection_path)
      |> halt
    else
      conn
    end
  end

  defp redirection_path(conn, %Secret{verified?: false}) do
    secret_path(conn, :verify_prompt)
  end

  defp redirction_path(conn, nil) do
    secret_path(conn, :new)
  end

  defp redirection_path(conn, secret = %Secret{}) do
    raise "Unexpected secret value: #{inspect secret}"
  end

  defp redirection_path(conn, secret) do
    Logger.debug("Treating secret value [#{inspect secret}] as missing secret.")
    secret_path(conn, :new)
  end

  defp redirection_message(%Secret{verified?: false}) do
    "We kindly ask you to verify your Secret Passphrase first"
  end

  defp redirection_message(_secret) do
    "We kindly ask you to setup your Secret Passphrase"
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :browser_auth do
    plug FileSurrender.AuthPipeline
    plug :process_last_redirected_path
    plug :redirect_to_secret_entry_or_verification
    plug :redirect_to_unauthorized_path
    plug :redirect_to_unverified_secret_path
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FileSurrenderWeb do
    pipe_through [:browser, :browser_auth] # Use the default browser stack

    get "/", PageController, :index
    get "/passwords", PasswordController, :index

  end

  scope "/auth", FileSurrenderWeb do
    pipe_through [:browser]

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  scope "/secure", FileSurrenderWeb do
    pipe_through [:browser, :browser_auth]

    resources "/entries", EntryController
    get "/secret", SecretController, :show
    get "/secret/create", SecretController, :new
    post "/secret/create", SecretController, :create
    get "/secret/edit", SecretController, :edit
    put "/secret/edit", SecretController, :update
    get "/secret/verify", SecretController, :verify_prompt
    patch "/secret/verify", SecretController, :verify
    delete "/secret/delete", SecretController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", FileSurrenderWeb do
  #   pipe_through :api
  # end
end
