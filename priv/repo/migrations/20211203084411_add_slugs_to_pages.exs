defmodule CoastSnap.Repo.Migrations.AddSlugsToPages do
  use Ecto.Migration

  def change do
    alter table(:pages) do
        add :slug, :string
    end
    create index(:pages, [:slug], unique: true)
  end
end
