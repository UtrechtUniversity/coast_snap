defmodule CoastSnap.GenServers.SnapProcessingQueue do
    use GenServer

    alias CoastSnap.SnapShots
    require Logger

    # tick interval is every 10 seconds
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
        { :ok, %{ queue: :queue.new() } }
    end

    def process_snap(snap) do
        GenServer.cast(__MODULE__, { :process_snap, snap })
    end

    def remove_snap(snap) do
        GenServer.call(__MODULE__, { :remove_snap, snap })
    end

    def handle_cast({ :process_snap, snap }, state) do
        %{ queue: queue } = state

        # start processing the image
        filepath =
            snap.org_filename
            |> SnapShots.local_path()
        # gather relevant data in struct
        data = %{
            id: snap.id,
            filepath: filepath,
            location: snap.location,
            country: snap.country,
            timestamp: get_timestamp(),
            pending_since: nil
        }
        # add path plus timestamp to queue
        queue = :queue.in(data, queue)
        # (queue has now 1 element at least) -- 2 scenario's:
        # first item is pending (in process), do nothing, data is added
        # first item is not pending, send the request and set the
        # pending_since to a timestamp
        head = :queue.head(queue)
        new_queue = case is_nil(head.pending_since) do
            true -> send_processing_request(queue)
            false -> queue
        end

        # return
        { :noreply, %{ queue: new_queue } }
    end

    def handle_call({ :remove_snap, snap}, _payload, state) do
        %{ queue: queue } = state
        # remove this item from queue
        new_queue = remove_from_queue(snap, queue)

        new_queue = case :queue.len(new_queue) == 0 do
            true -> new_queue # send back empty queue when empty
            false -> send_processing_request(new_queue)
        end

        { :reply, :ok, %{ queue: new_queue } }
    end

    def handle_info(:tick, state) do
        # verify if there is an images that is hanging
        %{ queue: queue } = state

        # current time
        time = get_timestamp()

        # if there are waiting jobs, and the state is pending
        # (waiting for a return) and it has been too long, then
        # move on to the next one
        head = :queue.peek(queue)

        # is head empty?
        new_queue = case head == :empty do
            true -> queue # queue is empty
            false ->
                # ok we have an item, get it
                { :value, item } = head
                cond do
                    is_nil(item.pending_since) == true ->
                        # this is weird, this item needs processing
                        send_processing_request(queue)

                    time - item.pending_since > Application.get_env(:coast_snap, :processing_timeout) ->
                        # it has been longer than 5 mins since the request
                        # remove it, the next one will get processed in the
                        # next tick

                        # get snap
                        snap = SnapShots.get_snap_shot(item.id)
                        # update to indicate failure
                        update_params = %{
                            "proc_filename" => Application.get_env(
                                :coast_snap,
                                :failure_message
                            ),
                            "is_processed" => false
                        }
                        # update
                        { :ok, snap } = SnapShots.update_snap(snap, update_params)
                        # notify LiveView
                        Phoenix.PubSub.broadcast(
                            CoastSnap.PubSub,
                            "python:#{snap.id}",
                            { :processing_done, snap }
                        )
                        # remove from queue
                        remove_from_queue(item, queue)

                    true ->
                        # all seems normal, let's wait
                        queue
                end
        end

        { :noreply, %{ queue: new_queue } }
    end

    defp remove_from_queue(snap, queue) do
        # predicate for finding the item we are looking for
        pred = fn(item) -> item.id == snap.id end
        # remove this item from queue
        :queue.delete_with(pred, queue)
    end

    defp send_processing_request(queue) do
        # get the next item from queue
        { item_tuple, new_queue } = :queue.out(queue)
        # if it is an item and not empty
        case item_tuple == :empty do
            true -> new_queue # nothing in queue, return empty queue
            false ->
                # get data
                { :value, snap_data } = item_tuple
                # prep request
                headers = [{"Content-type", "application/json"}]
                body = Jason.encode!(%{
                    snap_id: snap_data.id,
                    snap_filepath: snap_data.filepath,
                    snap_location: snap_data.location,
                    snap_country: snap_data.country
                })
                # request
                HTTPoison.post("http://127.0.0.1:8000/snap", body, headers, [])
                # change snap data, label time of starting the processing
                snap_data = Map.put(snap_data, :pending_since, get_timestamp())
                # put back on front in queue
                :queue.in_r(snap_data, new_queue)
        end
    end

    defp get_timestamp() do
        :os.system_time(:second)
    end

end
