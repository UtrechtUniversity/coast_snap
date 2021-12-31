defmodule CoastSnap.Repo.Migrations.AddPurposeFieldToSnapShots do
  use Ecto.Migration

  def change do
    create table(:uploads) do
      add :filename, :string
      add :size, :integer
      add :content_type, :string

      timestamps()
    end
    create index(:uploads, [:filename])
  end
end
