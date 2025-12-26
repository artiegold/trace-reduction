defmodule TicketProcessor.Tickets.TicketDependency do
  @moduledoc """
  Represents a dependency relationship between tickets.
  """
  use Ash.Resource,
    domain: TicketProcessor.Tickets,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("ticket_dependencies")
    repo(TicketProcessor.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    
    attribute :dependency_type, :atom do
      allow_nil?(false)
      default(:blocks)
      constraints(one_of: [:blocks, :duplicate_of])
    end
    
    attribute :dependency_data, :string do
      allow_nil?(false)
      constraints(max_length: 255)
    end

    create_timestamp(:created_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :blocking_ticket, TicketProcessor.Tickets.Ticket do
      allow_nil?(false)
    end
    
    belongs_to :dependent_ticket, TicketProcessor.Tickets.Ticket do
      allow_nil?(false)
    end
  end

  actions do
    read :read do
      primary?(true)
    end

    create :create do
      primary?(true)
      accept([:dependency_type, :dependency_data, :blocking_ticket_id, :dependent_ticket_id])
    end
  end
end