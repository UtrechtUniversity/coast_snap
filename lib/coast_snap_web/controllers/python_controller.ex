defmodule CoastSnapWeb.PythonController do

    use CoastSnapWeb, :controller

    alias CoastSnap.GenServers.SnapProcessingQueue
    alias CoastSnap.SnapShots

    def update(conn, params) do
        %{ "id" => id, "processed_filepath" => filepath } = params
        snap = SnapShots.get_snap_shot(id)

        failure_message = Application.get_env(
            :coast_snap,
            :failure_message
        )

        location_message = Application.get_env(
            :coast_snap,
            :location_failure
        )

        is_processed = case Enum.member?([failure_message, location_message], filepath) do
            true -> false
            false -> true
        end

        update_params = %{
            "proc_filename" => filepath,
            "is_processed" => is_processed
        }

        { :ok, snap } = SnapShots.update_snap(snap, update_params)

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
