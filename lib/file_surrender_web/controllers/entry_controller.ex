defmodule FileSurrenderWeb.EntryController do
  use FileSurrenderWeb, :controller

  alias FileSurrender.Secure
  alias FileSurrender.Secure.Entry

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

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

  def show(conn, %{"id" => id}) do
    entry = Secure.get_entry!(id)
    render(conn, "show.html", entry: entry)
  end

  def edit(conn, %{"id" => id}) do
    entry = Secure.get_entry!(id)
    changeset = Secure.change_entry(entry)
    render(conn, "edit.html", entry: entry, changeset: changeset)
  end

  def update(conn, %{"id" => id, "entry" => entry_params}) do
    entry = Secure.get_entry!(id)

    case Secure.update_entry(entry, entry_params) do
      {:ok, entry} ->
        conn
        |> put_flash(:info, "Entry updated successfully.")
        |> redirect(to: entry_path(conn, :show, entry))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", entry: entry, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    entry = Secure.get_entry!(id)
    {:ok, _entry} = Secure.delete_entry(entry)

    conn
    |> put_flash(:info, "Entry deleted successfully.")
    |> redirect(to: entry_path(conn, :index))
  end
end
