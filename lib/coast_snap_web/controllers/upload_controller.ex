# https://www.poeticoding.com/step-by-step-tutorial-to-build-a-phoenix-app-that-supports-user-uploads/
# check also endpoint.ex, there is a Plug.Static made there to serve the images

defmodule CoastSnapWeb.UploadController do

    use CoastSnapWeb, :controller

    alias CoastSnap.Resources.SnapShot
    alias CoastSnap.SnapShots

    require Logger

    def new(conn, params) do
        %{ "location" => location, "country" => country } = params
        changeset = SnapShot.create_changeset(%SnapShot{}, %{ location: location, country: country })
        render(conn, "new.html", %{
            country: country,
            location: location,
            changeset: changeset,
            layout: { CoastSnapWeb.LayoutView, "snap.html" }
        })
    end

    def create(conn, %{ "snap_shot" => snap_shot_params }) do
        %{ "location" => location, "country" => country } = snap_shot_params
        case SnapShots.create_original(snap_shot_params) do
            { :ok, response } ->
                { :ok, snap } = response
                # send snap to Gneerver to be processed later
                CoastSnap.GenServers.SnapProcessingQueue.process_snap(snap)
                # redirect to LiveView
                redirect(conn, to: "/#{country}/thankyou/#{snap.id}")
            { :error, reason } ->
                Logger.error(inspect(reason))
                put_flash(conn, :error, "Could not upload image")
                |> redirect(to: "/#{country}/#{location}/new")
        end
    end

end
