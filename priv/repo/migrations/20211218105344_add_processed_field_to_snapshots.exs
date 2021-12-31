defmodule CoastSnap.Repo.Migrations.AddProcessedFieldToSnapshots do
  use Ecto.Migration

  def change do
    alter table(:snap_shots) do
        add :is_processed, :boolean, default: false
    end
  end
end
