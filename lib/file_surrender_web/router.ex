defmodule FileSurrenderWeb.Router do
  use FileSurrenderWeb, :router

  require Ueberauth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :browser_auth do
    plug FileSurrender.AuthPipeline
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
    post "/secret/verify", SecretController, :verify
  end

  # Other scopes may use custom stacks.
  # scope "/api", FileSurrenderWeb do
  #   pipe_through :api
  # end
end
