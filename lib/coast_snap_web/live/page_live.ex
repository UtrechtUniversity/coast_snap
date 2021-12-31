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
    { :ok, assign(socket, :snap, snap) }
    end

    @impl true
    def handle_info({ :processing_done, snap }, socket) do
        { :noreply, assign(socket, :snap, snap) }
    end


end
