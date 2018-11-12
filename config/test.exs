use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :file_surrender, FileSurrenderWeb.Endpoint,
  http: [port: 4008],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :file_surrender, FileSurrender.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "file_surrender_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
