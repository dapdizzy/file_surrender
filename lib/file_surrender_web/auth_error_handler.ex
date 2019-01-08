defmodule FileSurrender.AuthErrorHandler do

  import Plug.Conn
  import Phoenix.Controller

  require Logger

  def auth_error(conn, {type, reason}, _opts) do
    Logger.debug "Authentication error of type #{type}, reason: #{reason}"
    conn
    |> put_session(:unauthorized_path, current_path(conn))
    # |> configure_session(drop: true)
    |> put_flash(:info, error_message(type, reason))
    |> redirect(to: "/")
  end

  defp error_message(:unauthenticated, :unauthenticated) do
    "Please authorize using either Google, Facebook or VK"
  end

  defp error_message(_type, _reason) do
    "We kindly ask you to reauthorize."
  end

  # Hide the type and reason from user for now.

  # defp error_message(type, reason) do
  #   "Authentication error of type #{type}, reason: #{reason}"
  # end
end
