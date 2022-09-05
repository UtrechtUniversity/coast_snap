defmodule CoastSnap.Repo.Migrations.AddSnapFieldsForProcessing do
  use Ecto.Migration

  def up do
    alter table(:snap_shots) do
        remove :original_id
        remove :is_original
        add :proc_filename, :string
    end
    rename table(:snap_shots), :filename, to: :org_filename
  end

  def down do
    alter table(:snap_shots) do

        add :original_id, :integer
        add :is_original, :boolean
        remove :proc_filename
    end
    rename table(:snap_shots), :org_filename, to: :filename
  end
end
