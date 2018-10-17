defmodule FileSurrenderWeb.EntryController do
  use FileSurrenderWeb, :controller

  alias FileSurrender.Secure
  alias FileSurrender.Secure.Entry

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    if user do
      entries = Secure.list_entries(user.id)
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
    case Secure.create_entry(entry_params |> Map.put("uid", user.id)) do # |> Map.put("id", 1)
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
