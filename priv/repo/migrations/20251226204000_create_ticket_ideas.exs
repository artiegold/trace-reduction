defmodule TicketProcessor.Repo.Migrations.CreateTicketIdeas do
  @moduledoc """
  Create ticket_ideas table for grouping related tickets.
  """

  use Ecto.Migration

  def up do
    create table(:ticket_ideas, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :title, :text, null: false
      add :description, :text, null: false
      add :status, :text, null: false, default: "active"
      add :created_at, :utc_datetime_usec, null: false, default: fragment("(now() AT TIME ZONE 'utc')")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("(now() AT TIME ZONE 'utc')"))
    end
  end

  def down do
    drop table(:ticket_ideas)
  end
end