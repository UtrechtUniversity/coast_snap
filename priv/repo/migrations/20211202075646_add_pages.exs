defmodule CoastSnap.Repo.Migrations.AddPages do
  use Ecto.Migration

    def change do
        create table(:pages) do
            add :position, :integer, default: 0
            add :parent_id, :integer, default: nil

            add :nav_en, :string
            add :content_en, :text

            add :nav_nl, :string
            add :content_nl, :text

            add :nav_ge, :string
            add :content_ge, :text
            timestamps()
        end
    end

end
