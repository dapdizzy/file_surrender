defmodule FileSurrender.Repo.Migrations.CreateEntries do
  use Ecto.Migration

  def change do
    create table(:entries) do
      add :uid, :binary
      add :name, :binary
      add :secret, :binary

      timestamps()
    end

  end
end
