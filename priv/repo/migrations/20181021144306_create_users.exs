defmodule FileSurrender.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :uid_hash, :string
      add :key_hash, :text

      timestamps()
    end

    alter table(:entries) do
      add :user_id, references(:users)
    end

    create unique_index(:users, [:uid_hash])

    create index(:entries, [:user_id])
  end
end
