defmodule CoastSnap.Repo.Migrations.AddIsOriginalToSnaps do
  use Ecto.Migration

  def change do
    alter table(:snap_shots) do
        add :is_original, :boolean, default: false
        add :original_id, :bigint
    end
  end
end
