defmodule CoastSnap.Repo.Migrations.AddStatusToPages do
  use Ecto.Migration

  def change do
    alter table(:pages) do
        add :status, :string, default: "hidden"
    end
  end
end
