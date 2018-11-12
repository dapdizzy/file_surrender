defmodule FileSurrenderWeb.PageController do
  use FileSurrenderWeb, :controller
  alias FileSurrender.Secure

  # plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    action_required = !!(user && Secure.has_entries_by_uid(user.id))
    secret_needed = !!(user && user.secret == nil)
    render conn, "index.html", current_user: user, action_required: action_required, secret_needed: secret_needed
    # , code: get_session(conn, :code)
  end

  def unauthenticated(conn, _params) do
    conn
    |> redirect(to: "/")
  end
end
