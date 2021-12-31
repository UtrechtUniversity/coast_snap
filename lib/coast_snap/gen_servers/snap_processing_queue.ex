defmodule CoastSnap.GenServers.SnapProcessingQueue do
    use GenServer

    alias CoastSnap.SnapShots
    require Logger

    # tick interval is every 30 seconds
    @tick_interval 10_000

    def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def init(_opts) do
        # start HTTPoison
        HTTPoison.start
        # start a timer
        :timer.send_interval(@tick_interval, :tick)
        # add a queue
        { :ok, %{ queue: :queue.new(), pending: false } }
    end

    def process_snap(snap) do
        GenServer.cast(__MODULE__, { :process_snap, snap })
    end

    def remove_snap(snap) do
        GenServer.call(__MODULE__, { :remove_snap, snap })
    end

    def handle_cast({ :process_snap, snap }, state) do
        %{ queue: queue, pending: pending } = state

        # start processing the image
        filepath =
            snap.filename
            |> SnapShots.local_path()
        # gather relevant data in struct
        data = %{
            id: snap.id,
            filepath: filepath,
            location: snap.location,
            country: snap.country,
            timestamp: :os.system_time(:second)
        }
        # add path plus timestamp to queue
        queue = :queue.in(data, queue)
        # if there is something pending than we keep things as is and wait
        # otherwise go for it and send to the python process
        pending = case pending do
            true -> true
            false ->
                send_processing_request(data)
                true
        end

        # return
        { :noreply, %{ queue: queue, pending: pending } }
    end

    def handle_call({ :remove_snap, snap}, _payload, state) do
        %{ queue: queue, pending: pending } = state
        # verify if snap is the one at head of queue
        head = :queue.head(queue)
        { new_queue, pending } = case head.id == snap.id and pending == true do
            true ->
                # remove from queue
                { _item, queue } = :queue.out(queue)
                # if queue is empty, then release, otherwise start
                # processing the next
                pending = case :queue.is_empty(queue) do
                    true -> false
                    false ->
                        send_processing_request(:queue.head(queue))
                        true
                end
                { queue, pending }
            false -> { queue, true }
        end

        { :reply, :ok, %{ queue: new_queue, pending: pending } }
    end

    def handle_info(:tick, state) do
        # verify if there is an images that is hanging
        { :noreply, state }
    end

    defp send_processing_request(snap_data) do
        headers = [{"Content-type", "application/json"}]
        body = Jason.encode!(%{
            snap_id: snap_data.id,
            snap_filepath: snap_data.filepath,
            snap_location: snap_data.location,
            snap_country: snap_data.country
        })
        HTTPoison.post("http://127.0.0.1:8000/snap", body, headers, [])
    end

end
