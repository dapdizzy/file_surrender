defmodule FileSurrenderWeb.AuthController do
  use FileSurrenderWeb, :controller
  # plug FileSurrenderWeb.Plugs.VKHash
  plug Ueberauth

  require Logger

  alias Ueberauth.Strategy.Helpers

  def request(conn, _params) do
    text conn, "How did you even get there?!!!"
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You've been logged out!")
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_failure: _failrure} = assigns} = conn, _params) do
    Logger.debug("ueberauth failure. Assigns: #{inspect assigns}")
    conn
    |> put_flash(:error, "Failed to log in.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
    Logger.debug "auth: #{inspect auth}"
    case UserFromAuth.find_or_create(auth) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        # |> put_session(:current_user, user)
        |> Guardian.Plug.sign_in(FileSurrender.Guardian, user)
        |> put_session(:code, params["code"])
        |> redirect(to: "/")
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end
end
