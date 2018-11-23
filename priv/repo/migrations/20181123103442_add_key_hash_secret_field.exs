defmodule FileSurrender.Repo.Migrations.AddKeyHashSecretField do
  use Ecto.Migration

  def change do
    alter table(:secrets) do
      add :key_hash, :text
    end
  end
end
