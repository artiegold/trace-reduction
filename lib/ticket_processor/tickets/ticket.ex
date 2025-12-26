defmodule TicketProcessor.Tickets.Ticket do
  @moduledoc """
  The ticket resource for processing support tickets.
  """
  use Ash.Resource,
    domain: TicketProcessor.Tickets,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPhoenix]

  postgres do
    table("tickets")
    repo(TicketProcessor.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :title, :string do
      allow_nil?(false)
      constraints(max_length: 255)
    end

    attribute :description, :string do
      allow_nil?(false)
      constraints(max_length: 2000)
    end

    attribute :status, :atom do
      allow_nil?(false)
      default(:open)
      constraints(one_of: [:open, :in_progress, :resolved, :closed, :discarded])
    end

    attribute :priority, :atom do
      allow_nil?(false)
      default(:medium)
      constraints(one_of: [:low, :medium, :high, :urgent])
    end

    attribute :assigned_to, {:array, :string} do
      default([])
      constraints(items: [max_length: 100])
    end

    attribute :blocks_resolution, :atom do
      allow_nil?(false)
      default(:none)
      constraints(one_of: [:none, :resolved, :blocked_by_dependencies])
    end

    attribute :depends_on_person, :string do
      allow_nil?(true)
      constraints(max_length: 100)
    end

    create_timestamp(:created_at)
    update_timestamp(:updated_at)
  end

  actions do
    read :read do
      primary?(true)
    end

    create :create do
      accept([:title, :description, :priority, :assigned_to, :depends_on_person])
    end

    update :update do
      accept([:title, :description, :priority, :assigned_to, :depends_on_person])
    end

    read :list do
    end

    update :resolve do
      accept([])
      change(set_attribute(:status, :resolved))
    end

    update :close do
      accept([])
      change(set_attribute(:status, :closed))
    end

    update :discard do
      accept([])
      change(set_attribute(:status, :discarded))
    end

    update :block_resolution do
      accept([])
      change(set_attribute(:blocks_resolution, :blocked_by_dependencies))
    end

    update :unblock_resolution do
      accept([])
      change(set_attribute(:blocks_resolution, :none))
    end

    update :add_assignee do
      argument :assignee, :string do
        allow_nil?(false)
        constraints(max_length: 100)
      end
      
      change(fn changeset, _context ->
        assignee = Ash.Changeset.get_argument(changeset, :assignee)
        current_assignees = Ash.Changeset.get_attribute(changeset, :assigned_to) || []
        
        if assignee not in current_assignees do
          Ash.Changeset.change_attribute(changeset, :assigned_to, current_assignees ++ [assignee])
        else
          changeset
        end
      end)
    end

    update :remove_assignee do
      argument :assignee, :string do
        allow_nil?(false)
        constraints(max_length: 100)
      end
      
      change(fn changeset, _context ->
        assignee = Ash.Changeset.get_argument(changeset, :assignee)
        current_assignees = Ash.Changeset.get_attribute(changeset, :assigned_to) || []
        
        Ash.Changeset.change_attribute(changeset, :assigned_to, List.delete(current_assignees, assignee))
      end)
    end

    update :change_ticket do
      argument :ticket, :map do
        allow_nil?(false)
      end
      
      change(fn changeset, _context ->
        ticket_args = Ash.Changeset.get_argument(changeset, :ticket)
        
        changeset
        |> Ash.Changeset.change_attribute(:title, Map.get(ticket_args, "title"))
        |> Ash.Changeset.change_attribute(:description, Map.get(ticket_args, "description"))
        |> Ash.Changeset.change_attribute(:priority, Map.get(ticket_args, "priority"))
        |> Ash.Changeset.change_attribute(:depends_on_person, Map.get(ticket_args, "depends_on_person"))
      end)
    end

    read :blocking_tickets do
      filter(expr(blocks_resolution == :blocked_by_dependencies))
    end

    read :person_dependent_tickets do
      filter(expr(not is_nil(depends_on_person)))
    end
  end

  relationships do
    has_many :dependencies, TicketProcessor.Tickets.TicketDependency,
      destination_attribute: :dependent_ticket_id,
      source_attribute: :id
    
    has_many :blocking_tickets, TicketProcessor.Tickets.TicketDependency,
      destination_attribute: :blocking_ticket_id,
      source_attribute: :id
  end

  identities do
    identity(:unique_title, [:title])
  end

  code_interface do
    define(:add_assignee, args: [:assignee])
    define(:remove_assignee, args: [:assignee])
    define(:change_ticket, args: [:ticket])
  end
end