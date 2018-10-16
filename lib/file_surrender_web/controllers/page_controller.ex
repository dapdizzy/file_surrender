defmodule FileSurrenderWeb.PageController do
  use FileSurrenderWeb, :controller

  # plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    render conn, "index.html", current_user: user
    # , code: get_session(conn, :code)
  end

  def unauthenticated(conn, _params) do
    conn
    |> redirect(to: "/")
  end
end
