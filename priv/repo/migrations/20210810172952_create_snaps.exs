defmodule CoastSnap.Repo.Migrations.CreateSnaps do
  use Ecto.Migration

  def change do
    create table(:snap_shots) do
      add :filename, :string
      add :location, :integer
      add :size, :integer

      timestamps()
    end
    create index(:snap_shots, [:filename])
  end
end
