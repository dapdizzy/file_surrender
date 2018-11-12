defmodule FileSurrender.Repo.Migrations.CreateSecrets do
  use Ecto.Migration

  def change do
    create table(:secrets) do
      add :secret, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:secrets, [:user_id])
  end
end
