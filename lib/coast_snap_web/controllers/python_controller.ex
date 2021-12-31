defmodule CoastSnapWeb.PythonController do

    use CoastSnapWeb, :controller

    alias CoastSnap.GenServers.SnapProcessingQueue
    alias CoastSnap.SnapShots

    def update(conn, params) do
        %{ "id" => id, "processed_filepath" => filepath } = params
        { :ok, snap } =
            id
            |> SnapShots.get_snap_shot()
            |> SnapShots.snap_is_processed()
        # create the new snap in the database, for the processed snap
        { :ok, _processed } = SnapShots.create_processed(snap, filepath)
        # notify the GenServer
        SnapProcessingQueue.remove_snap(snap)
        # notify LiveView
        Phoenix.PubSub.broadcast(
            CoastSnap.PubSub,
            "python:#{snap.id}",
            { :processing_done, snap }
        )
        # send a 200
        send_resp(conn, 200, "")
    end

end
