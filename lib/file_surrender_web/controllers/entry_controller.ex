defmodule FileSurrenderWeb.EntryController do
  use FileSurrenderWeb, :controller

  alias FileSurrender.Secure
  alias FileSurrender.Secure.Entry
  alias FileSurrender.Secure.Secret

  require Logger

  # plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__
  plug FileSurrender.AuthUserPipeline
  plug :authorize_entry when action in [:edit, :update, :delete, :show]

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

  def show(conn, _params) do
    # entry = Secure.get_entry!(id)
    entry = conn.assigns.entry
    render(conn, "show.html", entry: entry)
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
end
