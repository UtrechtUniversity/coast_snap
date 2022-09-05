defmodule CoastSnapWeb.Admin.YodaLive do
    use CoastSnapWeb, :live_view

    alias CoastSnap.Resources.YodaRequest

    @impl true
    def mount(_params, _session, socket) do
        case connected?(socket) do
            true ->
                # create a channel for the python communication
                Phoenix.PubSub.subscribe(CoastSnap.PubSub, "yoda")
            false ->
                :ok
        end

        today = NaiveDateTime.utc_now
        week_ago = NaiveDateTime.add(today, -1 * 7 * 24 * 3600, :second)

        socket = assign(
            socket,
            changeset: YodaRequest.changeset(
                %YodaRequest{},
                %{ "start_date" => week_ago, "end_date" => today }
            ),
            keys: [],
            transfers: %{}
        )

        { :ok, socket }
    end

    @impl true
    def handle_event("save", %{ "yoda_request" => request_params } = _value, socket) do
        { keys, transfers } = CoastSnap.GenServers.YodaTransfer.config_transfer(request_params)
            |> convert_transfers()

        socket = assign(
            socket,
            transfers: transfers,
            keys: keys
        )
        { :noreply, socket }
    end

    @impl true
    def handle_event("transfer", _params, socket) do
        CoastSnap.GenServers.YodaTransfer.transfer()
        { :noreply, socket }
    end

    @impl true
    def handle_event("reset", _params, socket) do
        { keys, transfers } = CoastSnap.GenServers.YodaTransfer.reset()
            |> convert_transfers()

        socket = assign(socket,
            transfers: transfers,
            keys: keys
        )

        { :noreply, socket }
    end

    # update status transferred file
    @impl true
    def handle_info({ :transferred, file_object }, socket) do
        # get transfer map from socket
        transfers = socket.assigns.transfers
        # update
        new_transfers = Map.put(transfers, file_object.target_path, file_object)
        # update socket
        socket = assign(socket, :transfers, new_transfers)

        { :noreply, socket }
    end



    defp convert_transfers(transfers) do
        transfer_map = transfers
            |> Enum.map(fn item -> { item.target_path, item } end)
            |> Map.new()
        keys = Enum.map(transfers, &(&1.target_path))
        { keys, transfer_map }
    end

end
