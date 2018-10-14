defmodule FileSurrender.AuthPipeline do
  use Guardian.Plug.Pipeline, otp_app: :file_surrender,
    module: FileSurrender.Guardian,
    error_handler: FileSurrender.AuthErrorHandler

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.LoadResource, allow_blank: true
end
