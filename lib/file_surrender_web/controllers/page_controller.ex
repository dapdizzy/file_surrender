defmodule FileSurrenderWeb.PageController do
  use FileSurrenderWeb, :controller
  alias FileSurrender.Secure
  alias FileSurrender.Secure.Secret

  # require Logger

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
