# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :coast_snap,
  ecto_repos: [CoastSnap.Repo],
  failure_message: "processing_failed",
  location_failure: "non_existent_location",
  processing_timeout: 2 * 60

# Configures the endpoint
config :coast_snap, CoastSnapWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "d6oZhX6o4WbtKSqxCBdjtbSAgzL008H17IvRw+ZCD7dshOiyVjYsFY5w/3xo+EN2",
  render_errors: [view: CoastSnapWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: CoastSnap.PubSub,
  live_view: [signing_salt: "3q9Wj0tw"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
