defmodule FileSurrender.AuthErrorHandler do

  import Plug.Conn
  import Phoenix.Controller

  require Logger

  def auth_error(conn, {type, reason}, _opts) do
    Logger.debug "Authentication error of type #{type}, reason: #{reason}"
    conn
    # |> configure_session(drop: true)
    |> put_flash(:error, "Authentication error of type #{type}, reason: #{reason}")
    |> redirect(to: "/")
  end
end
