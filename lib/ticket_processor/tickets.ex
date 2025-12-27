defmodule TicketProcessor.Tickets do
  @moduledoc """
  The Tickets context for managing ticket resources.
  """

  use Ash.Domain

  resources do
    resource TicketProcessor.Tickets.Ticket do
      define(:create_ticket, action: :create)
      define(:list_tickets, action: :read)
      define(:get_ticket, action: :read, get_by: [:id])
      define(:update_ticket, action: :update)
      define(:change_ticket, action: :update)

      define(:add_assignee, args: [:assignee])
      define(:remove_assignee, args: [:assignee])
      define(:resolve_ticket, action: :resolve)
      define(:close_ticket, action: :close)
      define(:discard_ticket, action: :discard)
      define(:block_resolution_ticket, action: :block_resolution)
      define(:unblock_resolution_ticket, action: :unblock_resolution)
    end

    resource TicketProcessor.Tickets.TicketDependency do
      define(:create_dependency, action: :create)
      define(:list_dependencies, action: :read)
      define(:get_dependency, action: :read, get_by: [:id])
    end
  end
end
