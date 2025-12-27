defmodule TicketProcessor.Repo do
  use Ecto.Repo,
    otp_app: :ticket_processor,
    adapter: Ecto.Adapters.Postgres

  def installed_extensions do
    ["uuid-ossp", "pg_trgm"]
  end

  def init(_type, config) do
    config = Keyword.put(config, :telemetry_prefix, [:ticket_processor, :repo])
    {:ok, config}
  end
end
