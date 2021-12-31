defmodule CoastSnap.Uploads do

    alias CoastSnap.Repo
    alias CoastSnap.Resources.Upload
    alias CoastSnap.Pagination

    import Ecto.Query

    def upload_dir() do
        Application.get_env(:coast_snap, :uploads_dir)
    end

    def local_path(filename) do
        [upload_dir(), "#{filename}"]
        |> Path.join()
    end

    def create(params \\ %{}) do
        %{ "upload" => upload } = params
        %Plug.Upload{
            filename: filename,
            path: tmp_path,
            content_type: content_type
        } = upload

        Repo.transaction fn ->
            with {:ok, %File.Stat{size: size}} <- File.stat(tmp_path),
                {:ok, upload} <-
                    %Upload{} |> Upload.create_changeset(%{
                        filename: filename, content_type: content_type,
                        size: size })
                    |> Repo.insert(),

                :ok <- File.cp(tmp_path, local_path(filename))
            do
                {:ok, upload}
            else
                {:error, reason} -> Repo.rollback(reason)
            end
        end
    end

    def destroy(id) do
        upload = Repo.get!(Upload, id)
        file_path = local_path(upload.filename)
        Repo.transaction fn ->
            with { :ok, _ } <- Repo.delete(upload),
                :ok <- File.rm(file_path)
            do
                :ok
            else
                {:error, reason} -> Repo.rollback(reason)
            end
        end
    end

    def list(:paged, page \\ 1, per_page \\ 15) do
        Upload
        |> order_by(desc: :inserted_at)
        |> Pagination.page(page, per_page: per_page)
    end

    def get_upload(id) do
        Repo.get(Upload, id)
    end

end
