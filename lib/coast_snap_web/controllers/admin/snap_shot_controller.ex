# check also endpoint.ex, there is a Plug.Static made there to serve the images

defmodule CoastSnapWeb.Admin.SnapShotController do

    use CoastSnapWeb, :controller
    alias CoastSnap.SnapShots

    def index(conn, params) do
        page = Map.get(params, "page", 1)
        snaps = SnapShots.list(:paged, page)
        render(conn, :index, %{ snaps: snaps, page: page })
    end

    def show(conn, %{ "id" => id, "page" => page }) do
        snap = SnapShots.get_snap_shot(id)
        render(conn, :show, %{ snap: snap, page: page })
    end

    def download(conn, params) do
        %{ "id" => id } = params
        version = Map.get(params, "version", "org")
        # get snap
        snap = SnapShots.get_snap_shot(id)
        # get filename
        filename = case version == "org" do
            true -> snap.org_filename
            false -> snap.proc_filename
        end
        local_path = SnapShots.local_path(filename)
        send_download conn, { :file, local_path }, filename: filename
    end

    def delete(conn, %{ "id" => id }) do
        SnapShots.destroy(id)
        redirect conn, to: "/admin/snap_shots"
    end

end
