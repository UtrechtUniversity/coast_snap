defmodule CoastSnap.Resources.Upload do

    use Ecto.Schema
    import Ecto.Changeset

    schema "uploads" do
        field :filename, :string
        field :size, :integer
        field :content_type, :string

        timestamps()
    end

    def create_changeset(upload, params \\ %{}) do
        upload
        |> cast(params, [:filename, :size, :content_type])
        |> validate_required([:filename, :size, :content_type])
        |> validate_number(:size, greater_than: 0) #doesn't allow empty files
    end

end
