defmodule CoastSnap.Resources.Page do

    use Ecto.Schema
    import Ecto.Changeset

    schema "pages" do
        field :position, :integer, default: 1
        field :parent_id, :integer, default: nil
        field :slug, :string, unique: true

        field :nav_en, :string
        field :content_en, :string

        field :nav_nl, :string
        field :content_nl, :string

        field :nav_ge, :string
        field :content_ge, :string

        timestamps()
    end

    def changeset(page, params \\ %{}) do
        # process slug
        processed_slug =
            Map.get(params, "slug", "")
            |> String.downcase()
            |> String.replace(~r/\s+/, "_")
        params = Map.put(params, "slug", processed_slug)
        page
        |> cast(params, [:position, :parent_id, :slug, :nav_en, :content_en,
            :nav_nl, :content_nl, :nav_ge, :content_ge])
        |> validate_required([:position, :slug, :nav_en, :nav_nl, :nav_ge])
        |> unique_constraint(:slug)
    end

end
