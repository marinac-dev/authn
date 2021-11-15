defmodule Authn.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :password, :string
      add :key_id, :string
      add :cose_key, :binary

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end
