defmodule CoastSnap.SnapShots do

    alias CoastSnap.Repo
    alias CoastSnap.Resources.SnapShot
    alias CoastSnap.Pagination

    import Ecto.Query

    require Logger

    def upload_dir() do
        Application.get_env(:coast_snap, :snaps_dir)
    end

    def local_path(filename) do
        [upload_dir(), "#{filename}"]
        |> Path.join()
    end

    def generate_filename(filename, location) do
        local_time =
            NaiveDateTime.local_now
            |> DateTime.from_naive!("Etc/UTC")

        unix_timestamp =
            local_time
            |> DateTime.to_unix(:millisecond)

        "#{unix_timestamp}_#{location}_#{filename}"
    end

    def create_original(params \\ %{}) do
        %{ "location" => location, "upload" => upload, "country" => country } = params
        %Plug.Upload{
            filename: filename,
            path: tmp_path,
            content_type: content_type
        } = upload

        hash = get_hash(tmp_path)

        filename = generate_filename(filename, location)

        params = %{
            filename: filename,
            content_type: content_type,
            hash: hash,
            location: location,
            country: country,
            is_original: true
        }

        Repo.transaction fn ->
            with {:ok, %File.Stat{size: size}} <- File.stat(tmp_path),
                {:ok, upload} <- create_snap(Map.put(params, :size, size)),
                :ok <- File.cp(tmp_path, local_path(filename))
            do
                {:ok, upload}
            else
                {:error, reason} -> Repo.rollback(reason)
            end
        end
    end

    def create_processed(original, new_filepath) do
        # get size of new file
        {:ok, stat} = File.stat(new_filepath)
        %File.Stat{size: size} = stat
        # get hash
        hash = get_hash(new_filepath)
        # get params
        params = %{
            filename: Path.basename(new_filepath),
            content_type: original.content_type,
            hash: hash,
            size: size,
            location: original.location,
            country: original.country,
            is_original: false,
            original_id: original.id
        }
        create_snap(params)
    end

    def create_snap(params \\ %{}) do
        %SnapShot{}
        |> SnapShot.create_changeset(params)
        |> Repo.insert()
    end

    def snap_is_processed(snap) do
        snap
        |> SnapShot.processed_changeset(%{ is_processed: true })
        |> Repo.update()
    end

    def destroy(id) do
        snap = Repo.get!(SnapShot, id)
        file_path = local_path(snap.filename)
        Repo.transaction fn ->
            with { :ok, _ } <- Repo.delete(snap),
                :ok <- File.rm(file_path)
            do
                :ok
            else
                {:error, reason} -> Repo.rollback(reason)
            end
        end
    end

    def list(:paged, page \\ 1, per_page \\ 15) do
        SnapShot
        |> order_by(desc: :inserted_at)
        |> Pagination.page(page, per_page: per_page)
    end

    def get_snap_shot(id) do
        Repo.get(SnapShot, id)
    end

    defp get_hash(path) do
        path
        |> File.stream!([], 2048)
        |> SnapShot.sha256()
    end

end
