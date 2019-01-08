defmodule FileSurrenderWeb.PageController do
  use FileSurrenderWeb, :controller
  alias FileSurrender.Secure
  alias FileSurrender.Secure.Secret

  require Logger

  defp process_last_redirected_path(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp process_last_redirected_path(conn, _options) do
    case conn |> get_session(:last_redirected_path) do
      nil -> conn
      path ->
        if path in [secret_path(conn, :new), secret_path(conn, :verify_prompt)] do
          Logger.debug("Skipping redirection back from a redirected url")
          conn
          |> put_flash(:info, "If you wanna go back. we're taking you there, no problem.")
          |> delete_session(:last_redirected_path)
          |> assign(:skip_redirection, true)
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
    unless prev_path in [secret_path(conn, :new), secret_path(conn, :verify_prompt)] do
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

  defp redirection_path(secret) do
    Logger.debug("Treating secret value [#{inspect secret}] as missing secret.")
    secret_path(conn, :new)
  end

  defp redirection_message(%Secret{verified?: false}) do
    "We kindly ask you to verify your Secret Passphrase first"
  end

  defp redirection_message(_secret) do
    "We kindly ask you to setup your Secret Passphrase"
  end

  plug :process_last_redirected_path
  plug :redirect_to_secret_entry_or_verification

  # plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    action_required = !!(user && Secure.has_entries_by_uid(user.id))
    has_entries_by_id = (user && Secure.has_entries?(user.internal_id)) || false
    render conn, "index.html", current_user: user, action_required: action_required, secret: user && user.secret, has_entries: action_required || has_entries_by_id
    # , code: get_session(conn, :code)
  end

  def unauthenticated(conn, _params) do
    conn
    |> redirect(to: "/")
  end
end
