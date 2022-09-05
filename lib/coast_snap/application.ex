defmodule CoastSnap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # make sure there is an upload folder
    uploads_dir = Application.get_env(:coast_snap, :uploads_dir)
    :ok = File.mkdir_p!(Application.app_dir(:coast_snap, uploads_dir))

    children = [
      # Start the Ecto repository
      CoastSnap.Repo,
      # Start the Telemetry supervisor
      CoastSnapWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CoastSnap.PubSub},
      # Start the Endpoint (http/https)
      CoastSnapWeb.Endpoint,
      # Start a worker by calling: CoastSnap.Worker.start_link(arg)
      # {CoastSnap.Worker, arg}
      CoastSnap.GenServers.SnapProcessingQueue,
      CoastSnap.GenServers.YodaTransfer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CoastSnap.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CoastSnapWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
