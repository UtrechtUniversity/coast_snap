defmodule CoastSnap.Repo.Migrations.AddCountryToSnapshots do
  use Ecto.Migration

  def change do
    alter table(:snap_shots) do
        add :country, :string
    end
  end
end
