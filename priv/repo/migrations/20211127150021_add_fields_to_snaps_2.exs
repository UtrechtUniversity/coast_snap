defmodule CoastSnap.Repo.Migrations.AddFieldsToSnaps2 do
  use Ecto.Migration

  def change do
    alter table(:snap_shots) do
        add :content_type, :string
    end
  end
end
