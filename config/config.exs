# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :file_surrender,
  ecto_repos: [FileSurrender.Repo]

# Configures the endpoint
config :file_surrender, FileSurrenderWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4oySGO6Q/DOK9Vp43ruT0pm0rZK4CacCxEwyzxePzJqEVWxBZCroFW34wWfBm1Z/",
  render_errors: [view: FileSurrenderWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: FileSurrender.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configure Encryption.AES
config :file_surrender, Encryption.AES,
  keys: ["b01NEpuOIatjUUv1gxAouJ4b2B9c2+o5VPYlzfIRygE="]
  # TODO: Hardcode ENCRYPTION_KEYS for now to be able to decrypt after the environment variable was flushed due to closing the cmd session.
  # keys: System.get_env("ENCRYPTION_KEYS") |> String.split(",")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :debug
  # device: :standard_error

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]},
    facebook: {Ueberauth.Strategy.Facebook, [default_scope: "email,public_profile", display: "popup"]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  client_id: System.get_env("FACEBOOK_CLIENT_ID"),
  client_secret: System.get_env("FACEBOOK_CLIENT_SECRET")

config :file_surrender, FileSurrender.Guardian,
  issuer: "file_surrender",
  secret_key: System.get_env("GUARDIAN_SECRET")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
