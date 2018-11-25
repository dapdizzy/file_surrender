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

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :browser_auth do
    plug FileSurrender.AuthPipeline
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
