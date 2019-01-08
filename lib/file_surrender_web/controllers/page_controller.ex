defmodule FileSurrenderWeb.PageController do
  use FileSurrenderWeb, :controller
  alias FileSurrender.Secure
  alias FileSurrender.Secure.Secret

  require Logger

  defp redirect_to_secret_entry_or_verification(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp redirect_to_secret_entry_or_verification(conn, _options) do
    user = Guardian.Plug.current_resource(conn)
    case user do
      %{internal_id: id} ->
        has_none_or_any_secure_entries = !Secure.has_entries?(id) || Secure.has_secure_entries?(id)
        process_user_with_no_or_secure_only_entries(conn, has_none_or_any_secure_entries, user)
      nil ->
        conn
    end
  end

  defp process_user_with_no_or_secure_only_entries(conn, false, _user) do
    conn
  end

  defp process_user_with_no_or_secure_only_entries(conn, true, user) do
    case user do
      %{secret: nil} ->
        Logger.debug("No secret for a new user, navigate to secret creation right away.")
        conn
        |> redirect(to: secret_path(conn, :new))
        |> halt
      %{secret: %Secret{verified?: false}} ->
        Logger.debug("Unverified secret value. Redirecting to verify_prompt.")
        conn
        |> redirect(to: secret_path(conn, :verify_prompt))
        |> halt
      _ ->
        conn
    end
  end

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
