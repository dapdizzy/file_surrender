defmodule FileSurrenderWeb.EntryController do
  use FileSurrenderWeb, :controller

  alias FileSurrender.Secure
  alias FileSurrender.Secure.Entry
  alias FileSurrender.Secure.Secret

  require Logger

  # plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__
  plug FileSurrender.AuthUserPipeline
  plug :authorize_entry when action in [:edit, :update, :delete, :show]
  plug :require_secret
  plug :put_prev_path_to_assigns
  plug :verify_secret when action in [:edit, :update, :delete, :show]

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    if user do
      conn =
        case Secure.list_entries_by_id(user.internal_id) do
          [] ->
            if Secure.has_entries_by_uid(user.id) do
              # Perform the update procedure rewiring from user.id (uid) to user.internal_id
              Secure.rewire_entries(user.id, user.internal_id)
              entries = Secure.list_entries_by_id(user.internal_id) # Should return proper list now.
              conn |> assign(:entries, entries) |> put_flash(:info, "Your secure entries have been successfuly rewired to the new schema!")
            else
              conn |> assign(:entries, [])
            end
          list when list |> is_list() ->
            Logger.debug("Got entries list by user id #{user.internal_id}")
            conn |> assign(:entries, list)
        end
      if conn.assigns.entries
      |> Enum.any?(fn %Entry{secret: secret} ->
        case secret do
          "$V3$_" <> _secret_part -> true
          _ -> false
        end
      end) && unverified_secret?(user.secret, user) do
        conn
        |> put_flash(:info, "Please verify your Secret first.")
        |> redirect(to: secret_path(conn, :verify_prompt))
        |> halt()
      end
      render(conn, "index.html", entries: conn.assigns.entries)
    else
      Logger.debug("Got nil user from Guardian for secure/entries index action.")
      conn
      |> configure_session(renew: true)
      |> put_flash(:error, "Unauthorized access detected. Please Authorize.")
      |> redirect(to: "/")
    end
  end

  defp unverified_secret?(nil, user) do
    raise "For some reason there are V3 encrypted values for user [#{inspect user}], but there is nil secret for him..."
  end

  defp unverified_secret?(%Secret{verified?: verified}, _user) do
    !verified
  end

  def new(conn, _params) do
    changeset = Secure.change_entry(%Entry{})
    render(conn, "new.html", changeset: changeset)
  end

  defp atomize_keys(map) do
    for {k, v} <- map, into: %{}, do: {String.to_atom(k), v}
  end

  def create(conn, %{"entry" => entry_params}) do
    user = Guardian.Plug.current_resource(conn)
    IO.puts "entry_params: #{inspect entry_params}"
    case Secure.create_entry(entry_params |> Map.put("user_id", user.internal_id)) do # |> Map.put("id", 1)
      {:ok, entry} ->
        conn
        |> put_flash(:info, "Entry created successfully.")
        |> redirect(to: entry_path(conn, :show, entry))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  defp secret_verified?(nil) do
    false
  end

  defp secret_verified?(%{secret: nil}) do
    false
  end

  defp secret_verified?(%{secret: %Secret{verified?: verified}}) do
    verified
  end

  def show(conn, _params) do
    # entry = Secure.get_entry!(id)
    entry = conn.assigns.entry
    # if  (entry |> Entry.requires_verified_secret?)
    # && !(secret_verified?(Guardian.Plug.current_resource(conn))) do
    #   conn
    #   |> put_session(:unverified_secret_path, current_path(conn))
    #   |> put_flash(:info, "You need to verify your Secret first.")
    #   |> redirect(to: secret_path(conn, :verify_prompt))
    #   |> halt
    # else
    render(conn, "show.html", entry: entry)
    # end
  end

  def edit(conn, _params) do
    entry = conn.assigns.entry # Secure.get_entry!(id)
      |> Entry.decrypt_entry
    changeset = Secure.change_entry(entry)
    render(conn, "edit.html", entry: entry, changeset: changeset)
  end

  def update(conn, %{"entry" => entry_params}) do
    # entry = Secure.get_entry!(id)
    entry = conn.assigns.entry

    case Secure.update_entry(entry, entry_params) do
      {:ok, entry} ->
        conn
        |> put_flash(:info, "Entry updated successfully.")
        |> redirect(to: entry_path(conn, :show, entry))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", entry: entry, changeset: changeset)
    end
  end

  def delete(conn, _params) do
    entry = conn.assigns.entry
    {:ok, _entry} = Secure.delete_entry(entry)

    conn
    |> put_flash(:info, "Entry deleted successfully.")
    |> redirect(to: entry_path(conn, :index))
  end

  # Plugs
  defp authorize_entry(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp authorize_entry(conn, _options) do
    entry = Secure.get_entry(conn.params["id"])
    do_authorize_entry(conn, entry)
    # user = Guardian.Plug.current_resource(conn)
  end

  defp do_authorize_entry(%Plug.Conn{halted: true} = conn, _entry) do
    conn
  end

  defp do_authorize_entry(conn, nil) do
    process_entry_not_found conn
  end

  defp do_authorize_entry(conn, %Entry{user_id: user_id, id: id} = entry) do
    user = Guardian.Plug.current_resource(conn)
    if user_id == user.internal_id do
      conn |> assign(:entry, entry)
    else
      Logger.info("Entry with id [#{id}] does not belong to the current user [uid = #{user.id}, internal_id = #{user.internal_id}], but to the user with internal id [#{user_id}].")
      process_entry_not_found conn
      # conn
      # |> put_flash(:error, "Requested entry does not exist.") # Don't tell the real reason to the user
      # |> redirect(to: entry_path(conn, :index))
    end
  end

  defp process_entry_not_found(conn) do
    conn
    |> put_flash(:error, "Entry not found.")
    |> redirect(to: entry_path(conn, :index))
    |> halt()
  end

  defp verify_secret(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp verify_secret(conn, _options) do
    entry = conn.assigns[:entry]
    if entry && (entry |> Entry.requires_verified_secret?)
    && !(secret_verified?(Guardian.Plug.current_resource(conn))) do
      conn
      |> put_session(:unverified_secret_path, current_path(conn))
      |> put_flash(:info, "You need to verify your Secret first.")
      |> redirect(to: secret_path(conn, :verify_prompt))
      |> halt
    else
      conn
    end
  end

  defp require_secret(%Plug.Conn{halted: true} = conn, _options) do
    conn
  end

  defp require_secret(conn, _options) do
    user = Guardian.Plug.current_resource(conn)
    unless Secure.has_entries_by_uid(user.id) || Secure.has_entries?(user.internal_id) do
      case user do
        %{secret: nil} -> conn |> process_secret_required
        %{secret: %{verified?: verified}} ->
          process_secret_verified conn, verified
      end
    else
      conn
    end
  end

  defp process_secret_required(conn) do
    conn
    |> put_flash(:info, "First, you need to define your Secret")
    |> put_session(:unverified_secret_path, current_path(conn))
    |> redirect(to: secret_path(conn, :new))
    |> halt
  end

  defp process_secret_verified(conn, true) do
    conn
  end

  defp process_secret_verified(conn, false) do
    conn
    |> put_flash(:info, "You need to verify your Secret first")
    |> put_session(:unverified_secret_path, current_path(conn))
    |> redirect(to: secret_path(conn, :verify_prompt))
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
end
