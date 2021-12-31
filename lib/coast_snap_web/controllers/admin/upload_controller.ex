defmodule CoastSnapWeb.Admin.UploadController do

    use CoastSnapWeb, :controller
    alias CoastSnap.Resources.Upload
    alias CoastSnap.Uploads

    def index(conn, params) do
        page = Map.get(params, "page", 1)
        uploads = Uploads.list(:paged, page)
        changeset = Upload.create_changeset(%Upload{})
        render(conn, :index, %{ uploads: uploads, page: page, changeset: changeset })
    end

    def create(conn, %{ "upload" => upload_params }) do
        { status, _response } = Uploads.create(upload_params)
        conn = case status do
          :ok -> put_flash(conn, :info, "Upload successful")
          :error -> put_flash(conn, :error, "Upload unsuccessful")
        end
        redirect conn, to: "/admin/uploads"
    end

    def show(conn, %{ "id" => id, "page" => page }) do
        upload = Uploads.get_upload(id)
        render(conn, :show, %{ upload: upload, page: page })
    end

    def delete(conn, %{ "id" => id }) do
        Uploads.destroy(id)
        redirect conn, to: "/admin/uploads"
    end

end
