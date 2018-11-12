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

  describe "users" do
    alias FileSurrender.Secure.User

    @valid_attrs %{key_hash: "some key_hash", uid_hash: "some uid_hash"}
    @update_attrs %{key_hash: "some updated key_hash", uid_hash: "some updated uid_hash"}
    @invalid_attrs %{key_hash: nil, uid_hash: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Secure.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Secure.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Secure.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Secure.create_user(@valid_attrs)
      assert user.key_hash == "some key_hash"
      assert user.uid_hash == "some uid_hash"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Secure.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Secure.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.key_hash == "some updated key_hash"
      assert user.uid_hash == "some updated uid_hash"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Secure.update_user(user, @invalid_attrs)
      assert user == Secure.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Secure.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Secure.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Secure.change_user(user)
    end
  end

  describe "secrets" do
    alias FileSurrender.Secure.Secret

    @valid_attrs %{secret: "some secret"}
    @update_attrs %{secret: "some updated secret"}
    @invalid_attrs %{secret: nil}

    def secret_fixture(attrs \\ %{}) do
      {:ok, secret} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Secure.create_secret()

      secret
    end

    test "list_secrets/0 returns all secrets" do
      secret = secret_fixture()
      assert Secure.list_secrets() == [secret]
    end

    test "get_secret!/1 returns the secret with given id" do
      secret = secret_fixture()
      assert Secure.get_secret!(secret.id) == secret
    end

    test "create_secret/1 with valid data creates a secret" do
      assert {:ok, %Secret{} = secret} = Secure.create_secret(@valid_attrs)
      assert secret.secret == "some secret"
    end

    test "create_secret/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Secure.create_secret(@invalid_attrs)
    end

    test "update_secret/2 with valid data updates the secret" do
      secret = secret_fixture()
      assert {:ok, secret} = Secure.update_secret(secret, @update_attrs)
      assert %Secret{} = secret
      assert secret.secret == "some updated secret"
    end

    test "update_secret/2 with invalid data returns error changeset" do
      secret = secret_fixture()
      assert {:error, %Ecto.Changeset{}} = Secure.update_secret(secret, @invalid_attrs)
      assert secret == Secure.get_secret!(secret.id)
    end

    test "delete_secret/1 deletes the secret" do
      secret = secret_fixture()
      assert {:ok, %Secret{}} = Secure.delete_secret(secret)
      assert_raise Ecto.NoResultsError, fn -> Secure.get_secret!(secret.id) end
    end

    test "change_secret/1 returns a secret changeset" do
      secret = secret_fixture()
      assert %Ecto.Changeset{} = Secure.change_secret(secret)
    end
  end
end
