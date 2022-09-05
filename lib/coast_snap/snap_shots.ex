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

        date = Calendar.strftime(local_time, "%A.%B.%d_%H.%M.%S_%Y")
        extension = Path.extname(filename)
        # 1646404053.Friday.March.04_15.27.33_2022.egmond.snap.jpg
        "#{unix_timestamp}.#{date}.#{location}.snap#{extension}"
    end

    def create_original(params \\ %{}) do
        %{ "location" => location, "upload" => upload,
            "country" => country, "accepts_terms_of_agreement" => toa } = params

        %Plug.Upload{
            filename: filename,
            path: tmp_path,
            content_type: content_type
        } = upload

        hash = get_hash(tmp_path)

        filename = generate_filename(filename, location)

        params = %{
            org_filename: filename,
            content_type: content_type,
            hash: hash,
            location: location,
            country: country,
            accepts_terms_of_agreement: toa
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

    def update_snap(snap, params) do
        snap
        |> SnapShot.processed_changeset(params)
        |> Repo.update()
    end

    def create_snap(params \\ %{}) do
        %SnapShot{}
        |> SnapShot.create_changeset(params)
        |> Repo.insert()
    end

    def destroy(id) do
        snap = Repo.get!(SnapShot, id)
        org_filepath = local_path(snap.org_filename)
        proc_filepath = local_path(snap.proc_filename)
        Repo.transaction fn ->
            with { :ok, _ } <- Repo.delete(snap),
                :ok <- File.rm(org_filepath),
                :ok <- File.rm(proc_filepath)
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
