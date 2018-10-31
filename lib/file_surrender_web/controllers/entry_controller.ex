defmodule FileSurrenderWeb.EntryController do
  use FileSurrenderWeb, :controller

  alias FileSurrender.Secure
  alias FileSurrender.Secure.Entry

  require Logger

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__
  plug :authorize_entry when action in [:edit, :update, :delete, :show]

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    if user do
      entries =
        case Secure.list_entries_by_id(user.internal_id) do
          [] ->
            if Secure.has_entries_by_uid(user.id) do
              # Perform the update procedure rewiring from user.id (uid) to user.internal_id
              Secure.rewire_entries(user.id, user.internal_id)
              Secure.list_entries_by_id(user.internal_id) # Should return proper list now.
            else
              []
            end
          list when list |> is_list() ->
            list
        end
      render(conn, "index.html", entries: entries)
    else
      conn
      |> put_flash(:error, "Unauthorized access detected. Please Authorize.")
      |> configure_session(drop: true)
      |> redirect(to: "/")
    end

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
    entry = conn.asigns.entry

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
