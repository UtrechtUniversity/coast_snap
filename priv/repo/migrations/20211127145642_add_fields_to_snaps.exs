defmodule CoastSnap.Repo.Migrations.AddFieldsToSnaps do
  use Ecto.Migration

    def change do
        alter table(:snap_shots) do
            modify :size, :bigint
            add :hash, :string, size: 64
        end
    end

end
