defmodule FileSurrender.SecureTest do
  use FileSurrender.DataCase

  alias FileSurrender.Secure

  describe "entries" do
    alias FileSurrender.Secure.Entry

    @valid_attrs %{name: "some name", secret: "some secret", uid: "some uid"}
    @update_attrs %{name: "some updated name", secret: "some updated secret", uid: "some updated uid"}
    @invalid_attrs %{name: nil, secret: nil, uid: nil}

    def entry_fixture(attrs \\ %{}) do
      {:ok, entry} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Secure.create_entry()

      entry
    end

    test "list_entries/0 returns all entries" do
      entry = entry_fixture()
      assert Secure.list_entries() == [entry]
    end

    test "get_entry!/1 returns the entry with given id" do
      entry = entry_fixture()
      assert Secure.get_entry!(entry.id) == entry
    end

    test "create_entry/1 with valid data creates a entry" do
      assert {:ok, %Entry{} = entry} = Secure.create_entry(@valid_attrs)
      assert entry.name == "some name"
      assert entry.secret == "some secret"
      assert entry.uid == "some uid"
    end

    test "create_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Secure.create_entry(@invalid_attrs)
    end

    test "update_entry/2 with valid data updates the entry" do
      entry = entry_fixture()
      assert {:ok, entry} = Secure.update_entry(entry, @update_attrs)
      assert %Entry{} = entry
      assert entry.name == "some updated name"
      assert entry.secret == "some updated secret"
      assert entry.uid == "some updated uid"
    end

    test "update_entry/2 with invalid data returns error changeset" do
      entry = entry_fixture()
      assert {:error, %Ecto.Changeset{}} = Secure.update_entry(entry, @invalid_attrs)
      assert entry == Secure.get_entry!(entry.id)
    end

    test "delete_entry/1 deletes the entry" do
      entry = entry_fixture()
      assert {:ok, %Entry{}} = Secure.delete_entry(entry)
      assert_raise Ecto.NoResultsError, fn -> Secure.get_entry!(entry.id) end
    end

    test "change_entry/1 returns a entry changeset" do
      entry = entry_fixture()
      assert %Ecto.Changeset{} = Secure.change_entry(entry)
    end
  end
end
