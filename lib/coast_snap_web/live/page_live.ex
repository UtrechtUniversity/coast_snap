defmodule CoastSnapWeb.PageLive do
    use CoastSnapWeb, :live_view

    alias CoastSnap.SnapShots

    @impl true
    def mount(params, _session, socket) do
    %{ "id" => id } = params
    snap = SnapShots.get_snap_shot(id)
    case connected?(socket) do
        true ->
            # create a channel for the python communication
            Phoenix.PubSub.subscribe(CoastSnap.PubSub, "python:#{id}")
        false ->
            :ok
    end

    socket = assign(
        socket,
        snap: snap
    )

    { :ok, socket }
    end

    @impl true
    def handle_info({ :processing_done, new_snap }, socket) do
        # if incoming snap is correct (this is a bit much but I don't want people
        # to see the wrong snaps)
        socket = case new_snap.id == socket.assigns.snap.id do
            true -> assign(socket, snap: new_snap)
            false -> socket
        end

        { :noreply, socket }
    end

end
