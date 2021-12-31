defmodule CoastSnap.Repo.Migrations.Location do
  use Ecto.Migration

  def change do
    alter table(:snap_shots) do
      modify :location, :string
    end

  end
end
