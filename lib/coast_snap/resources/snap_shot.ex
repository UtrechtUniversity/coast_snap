defmodule CoastSnap.Resources.SnapShot do

    use Ecto.Schema
    import Ecto.Changeset

    schema "snap_shots" do
        field :org_filename, :string
        field :proc_filename, :string
        field :country, :string
        field :location, :string
        field :size, :integer
        field :hash, :string
        field :content_type, :string
        field :is_processed, :boolean, default: false
        field :accepts_terms_of_agreement, :boolean, default: false

        timestamps()
    end

    def sha256(chunks_enum) do
        chunks_enum
        |> Enum.reduce(
            :crypto.hash_init(:sha256),
            &(:crypto.hash_update(&2, &1))
        )
        |> :crypto.hash_final()
        |> Base.encode16()
        |> String.downcase()
    end

    def create_changeset(snap_shot, params \\ %{}) do
        snap_shot
        |> cast(params, [:org_filename, :country, :location, :size, :content_type,
            :hash, :accepts_terms_of_agreement])
        |> validate_required([:org_filename, :accepts_terms_of_agreement, :country, :location, :size, :content_type, :hash])
        |> validate_acceptance(:accepts_terms_of_agreement, message: "please accept our terms of agreement")
        |> validate_number(:size, greater_than: 0) # doesn't allow empty files
        |> validate_length(:hash, is: 64)
    end

    def processed_changeset(snap_shot, params \\ %{}) do
        snap_shot
        |> cast(params, [:proc_filename, :is_processed])
        |> validate_required([:proc_filename, :is_processed])
    end

end
