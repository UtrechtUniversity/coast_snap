defmodule CoastSnap.Repo do
  use Ecto.Repo,
    otp_app: :coast_snap,
    adapter: Ecto.Adapters.Postgres
end
