defmodule FileSurrender.AuthErrorHandler do

  import Plug.Conn
  import Phoenix.Controller

  require Logger

  def auth_error(conn, {type, reason}, _opts) do
    Logger.debug "Authentication error of type #{type}, reason: #{reason}"
    conn
    # |> configure_session(drop: true)
    |> put_flash(:error, error_message(type, reason))
    |> redirect(to: "/")
  end

  defp error_message(:unauthenticated, :unauthenticated) do
    "Please authorize using either Google, Facebook or VK"
  end

  defp error_message(type, reason) do
    "Authentication error of type #{type}, reason: #{reason}"
  end
end
