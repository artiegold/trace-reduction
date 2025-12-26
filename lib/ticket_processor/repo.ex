defmodule TicketProcessor.Repo do
  use Ecto.Repo,
    otp_app: :ticket_processor,
    adapter: Ecto.Adapters.Postgres

  def installed_extensions do
    ["uuid-ossp", "pg_trgm"]
  end
end
