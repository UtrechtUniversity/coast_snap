defmodule CoastSnap.Resources.SnapShot do

    use Ecto.Schema
    import Ecto.Changeset

    schema "snap_shots" do
        field :filename, :string
        field :country, :string
        field :location, :string
        field :size, :integer
        field :hash, :string
        field :content_type, :string
        field :is_processed, :boolean, default: false
        field :is_original, :boolean, default: false
        field :original_id, :integer, default: nil

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
        |> cast(params, [:filename, :country, :location, :size, :content_type, :hash, :is_original, :original_id])
        |> validate_required([:filename, :country, :location, :size, :content_type, :hash])
        |> validate_number(:size, greater_than: 0) # doesn't allow empty files
        |> validate_length(:hash, is: 64)
    end

    def processed_changeset(snap_shot, params \\ %{}) do
        snap_shot
        |> cast(params, [:is_processed])
    end

end
