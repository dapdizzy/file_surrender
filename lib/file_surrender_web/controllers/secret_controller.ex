defmodule FileSurrenderWeb.SecretController do
  use FileSurrenderWeb, :controller

  alias FileSurrender.Secure
  alias FileSurrender.Secure.Secret

  require Logger

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__
  plug :put_prev_path_to_assigns
  plug :authorize_secret
  plug :create_secret_first when action in [:index]
  plug :short_circuit_secret, [condition: &Secret.secret_verified?/1, message: "Your Secret has already been verified."] when action in [:verify, :verify_prompt]
  plug :short_circuit_secret, [condition: &Secret.has_secret?/1, message: "You already have your encryption Secret."] when action in [:create, :new]
  plug :short_circuit_secret, [condition: &Secret.has_no_secret?/1, message: "You do not have Secret value yet."] when action in [:edit, :update]
  plug :short_circuit_secret, [condition: &Secret.has_no_secret?/1, message: "You do not have Secret value yet."] when action in [:delete]

  def show(conn, _params) do
    render conn, "show.html", secret: conn.assigns.secret
  end

  def new(conn, _params) do
    changeset = Secure.change_secret(%Secret{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"secret" => secret_params}) do
    user = Guardian.Plug.current_resource(conn)
    case Secure.create_secret(secret_params, user.internal_id) do
      {:ok, %Secret{} = secret} ->
        UsersCache.add(user |> Map.put(:secret, %{secret|verified?: true})) # This way we update the user map stored in the cache
        conn
        |> put_flash(:info, "Your secret has been successfuly created.")
        |> redirect(to: entry_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render conn, "new.html", changeset: changeset
    end
  end

  def verify_prompt(conn, _params) do
    secret = conn.assigns.secret
    changeset = Secure.change_secret(secret)
    render conn, "verify.html", changeset: changeset
  end

  def verify(conn, %{"secret" => secret_params}) do
    user = Guardian.Plug.current_resource(conn)
    secret = conn.assigns.secret
    import Encryption.HashedField, only: [verify_secret: 2]
    unless verify_secret(open_secret = secret_params["open_secret"], secret.secret) do
      conn
      |> put_flash(:error, "Unfortunately, your Secret did not match the stored value. Please try again.")
      |> render("verify.html", changeset: Secure.change_secret(secret))
    else
      # This way we can update the secret stored for the user in cache.
      UsersCache.add(%{user|secret: Secure.set_secret_key_hash(%{secret|open_secret: open_secret, verified?: true})})
      conn
      |> put_flash(:info, "You have successfuly verified your Secret!")
      |> redirect(to: entry_path(conn, :index))
    end
  end

  def edit(conn, _params) do
    secret = conn.assigns.secret
    changeset = Secure.change_secret(secret)
    render conn, "edit.html", secret: secret, changeset: changeset
  end

  def update(conn, %{"secret" => secret_params}) do
    user = Guardian.Plug.current_resource(conn)
    secret = conn.assigns.secret

    case Secure.update_secret(secret, secret_params) do
      {:ok, %Secret{open_secret: open_secret, new_secret: new_secret} = updated_secret} ->
        # TODO: need to reencrypt all the user's data with the new_secret.
        # Here we are updating (reencrypting) all the user secure entries using updated secret value.
        Logger.debug("Going to reencrypt secure entries with the updated secret key for the user with id: #{user.internal_id}")
        counter = Secure.reencrypt_entries(user.internal_id, user.key_hash, open_secret, new_secret)
        Logger.debug("#{counter} secure entries were reencrypted with the updated security key for user with id: #{user.internal_id}")
        UsersCache.add(%{user|secret: updated_secret}) # Update secret value in users cache.
        conn
        |> put_flash(:info, "Your Secret has been successfuly updated! (#{counter} entries)")
        |> redirect(to: secret_path(conn, :show))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", secret: secret, changeset: changeset)
    end
  end

  def delete(conn, _params) do
    secret = conn.assigns.secret
    {:ok, _deleted_secret} = Secure.delete_secret(secret)

    user = Guardian.Plug.current_resource(conn)
    UsersCache.add(%{user|secret: nil})

    conn
    |> put_flash(:info, "Secret has been deleted!")
    |> redirect(to: secret_path(conn, :show))
  end

  defp authorize_secret(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp authorize_secret(conn, _options) do
    user = Guardian.Plug.current_resource(conn)
    do_authorize_secret(conn, user)
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

  defp short_circuit_secret(conn, options) do
    condition = options[:condition]
    unless condition |> is_function(1) do
      raise ":short_circuit_secret plug should have a valid :condition function/1."
    end
    message = options[:message]
    unless message && message |> is_binary do
      raise ":message option should be provided to :short_circuit_secret plug."
    end
    redirection_path = options[:redirection_path] || entry_path(conn, :index)
    if condition.(conn.assigns.secret) do
      conn
      |> put_flash(:info, message)
      |> redirect(to: redirection_path)
      |> halt
    else
      conn
    end
  end

  defp short_circuit_verified(conn, _options) do
    process_conn_secret conn, conn.assigns.secret
  end

  defp process_conn_secret(conn, %Secret{verified?: true}) do
    process_verified_conn conn
  end

  defp process_conn_secret(conn, _secret) do
    conn
  end

  defp process_verified_conn(conn) do
    conn
    |> put_flash(:info, "Your Secret already is verified!")
    |> redirect(to: entry_path(conn, :index))
    |> halt
  end

  defp put_prev_path_to_assigns(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp put_prev_path_to_assigns(conn, _options) do
    prev_path = conn |> get_session(:prev_path)
    if prev_path do
      conn |> assign(:prev_path, prev_path)
    else
      conn
    end
  end

  defp create_secret_first(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp create_secret_first(conn, _options) do
    user = Guardian.Plug.current_resource(conn)
    do_create_secret_for_user conn, user
  end

  defp do_create_secret_for_user(conn, user) do
    case user do
      %{secret: %Secret{}} ->
        conn
      _ ->
        Logger.debug("Kindly navigate to Secret passphrase creation first.")
        conn
        |> redirect(to: secret_path(conn, :new))
        |> halt
    end
  end

  def secret_path_export(conn, function) do
    secret_path(conn, function)
  end
end
