defmodule FileSurrenderWeb.SecretController do
  use FileSurrenderWeb, :controller

  alias FileSurrender.Secure
  alias FileSurrender.Secure.Secret

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__
  plug :authorize_secret

  def show(conn, _params) do
    render conn, "show.html", secret: conn.assigns.secret
  end

  def new(conn, _params) do
    changeset = Secure.change_secret(%Secret{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"secret" => secret_params}) do
    user = Guargian.Plug.current_resource(conn)
    case Secure.create_secret(secret_params, user.internal_id) do
      {:ok, %Secret{} = secret} ->
        UsersCache.add(user |> Map.put(:secret, %{secret|verified?: true})) # This way we update the user map stored in the cache
        conn
        |> put_flash(:info, "Your secret has been successfuly created.")
        |> redirect(to: "/")
      {:error, %Ecto.Changeset{} = changeset} ->
        render conn, "new.html", changeset: changeset
    end
  end

  def update(conn, %{"secret" => secret_params}) do
    secret = conn.assigns.secret

    case Secure.update_secret(secret, secret_params) do
      {:ok, %Secret{open_secret: open_secret, new_secret: new_secret}} ->
        # TODO: need to reencrypt all the user's data with the new_secret.
        conn
        |> put_flash(:info, "Your Secret has been successfuly updated!")
        |> redirect(to: secret_path(conn, :show))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", secret: secret, changeset: changeset)
    end
  end

  defp authorize_secret(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp authorize_secret(conn, _options) do
    user = Guardian.Plug.current_resource(conn)
    do_authorize_entry(conn, user)
  end

  defp do_authorize_secret(conn, nil) do
    process_unauthorized conn
  end

  defp do_authorize_secret(conn, %{secret: secret}) do
    conn
    |> assign(:secret, secret)
  end

  # TODO: probably those function clauses are not needed, as secret is already extracted in the user_from_auth.ex

  defp extract_secret(%Secret{secret: secret}) do
    secret
  end

  defp extract_secret(nil) do
    nil
  end

  defp process_unauthorized(conn) do
    conn
    |> put_flash(:error, "Please reauthorize.")
    |> redirect(to: page_path(conn, :index))
    |> halt()
  end
end
