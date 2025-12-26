defmodule TicketProcessor.TicketPropertiesTest do
  use ExUnit.Case, async: true
  use StreamData

  alias TicketProcessor.Tickets
  alias TicketProcessor.Tickets.Ticket

  @moduletag :property

  describe "Ticket algebraic properties" do
    test "create and read roundtrip" do
      ticket_generator = ticket_data_generator()

      property "creating a ticket and reading it back yields the same data" do
        check all(ticket_attrs <- ticket_generator) do
          {:ok, created_ticket} = Tickets.create_ticket(ticket_attrs)
          {:ok, read_ticket} = Tickets.get_ticket(created_ticket.id)

          assert created_ticket.id == read_ticket.id
          assert created_ticket.title == read_ticket.title
          assert created_ticket.description == read_ticket.description
          assert created_ticket.priority == read_ticket.priority
          assert created_ticket.status == read_ticket.status
          assert created_ticket.assigned_to == read_ticket.assigned_to
        end
      end
    end

    test "status update monotonicity" do
      ticket_generator = ticket_data_generator()

      property "status updates follow valid progression rules" do
        check all(ticket_attrs <- ticket_generator) do
          {:ok, ticket} = Tickets.create_ticket(ticket_attrs)

          # Test that status can only progress forward or stay same
          final_ticket = apply_random_status_updates(ticket)

          assert is_valid_status_progression(ticket.status, final_ticket.status)
        end
      end
    end

    test "list_tickets is idempotent" do
      ticket_generator = ticket_data_generator()

      property "calling list_tickets multiple times returns same results" do
        check all(ticket_attrs_list <- list(ticket_generator, min_length: 1, max_length: 5)) do
          # Create tickets
          for ticket_attrs <- ticket_attrs_list do
            Tickets.create_ticket(ticket_attrs)
          end

          # List tickets multiple times
          list1 = Tickets.list_tickets()
          list2 = Tickets.list_tickets()
          list3 = Tickets.list_tickets()

          # Should be identical (ignoring timestamps)
          assert length(list1) == length(list2) == length(list3)

          # Sort by ID for comparison
          sorted1 = Enum.sort_by(list1, & &1.id)
          sorted2 = Enum.sort_by(list2, & &1.id)
          sorted3 = Enum.sort_by(list3, & &1.id)

          assert sorted1 == sorted2 == sorted3
        end
      end
    end

    test "update commutativity for independent fields" do
      ticket_generator = ticket_data_generator()

      property "updating different fields in any order yields same result" do
        check all(ticket_attrs <- ticket_generator) do
          {:ok, ticket} = Tickets.create_ticket(ticket_attrs)

          # Update assigned_to and priority in different orders
          {:ok, ticket1} = update_assigned_to_then_priority(ticket)
          {:ok, ticket2} = update_priority_then_assigned_to(ticket)

          # Should end up with same values
          assert ticket1.assigned_to == ticket2.assigned_to
          assert ticket1.priority == ticket2.priority
          assert ticket1.status == ticket2.status
        end
      end
    end

    test "ticket uniqueness constraints" do
      unique_title_generator =
        gen all(title <- string(:alphanumeric, min_length: 10, max_length: 50)) do
          %{
            title: title,
            description: "Description for #{title}",
            priority: :medium
          }
        end

      property "tickets with same title cannot both exist" do
        check all(title <- string(:alphanumeric, min_length: 10, max_length: 50)) do
          ticket_attrs = %{
            title: title,
            description: "Description for #{title}",
            priority: :medium
          }

          # First ticket should succeed
          assert {:ok, _ticket1} = Tickets.create_ticket(ticket_attrs)

          # Second ticket with same title should fail
          assert {:error, _changeset} = Tickets.create_ticket(ticket_attrs)
        end
      end
    end
  end

  describe "Ticket statistical properties" do
    test "priority distribution" do
      priority_generator = member_of([:low, :medium, :high, :urgent])

      property "priority distribution follows expected pattern" do
        check all(priorities <- list(priority_generator, min_length: 100, max_length: 1000)) do
          # Create tickets with random priorities
          tickets =
            for priority <- priorities do
              {:ok, ticket} =
                Tickets.create_ticket(%{
                  title: "Ticket #{priority}",
                  description: "Description",
                  priority: priority
                })

              ticket
            end

          # Count priorities
          priority_counts =
            Enum.group_by(tickets, & &1.priority)
            |> Map.new(fn {k, v} -> {k, length(v)} end)

          # All priorities should be present
          assert Map.has_key?(priority_counts, :low)
          assert Map.has_key?(priority_counts, :medium)
          assert Map.has_key?(priority_counts, :high)
          assert Map.has_key?(priority_counts, :urgent)

          # Total should match
          total_tickets = length(tickets)
          counted_total = Map.values(priority_counts) |> Enum.sum()
          assert total_tickets == counted_total
        end
      end
    end

test "status transition probabilities" do
      ticket_generator = ticket_data_generator()

      property "status transitions follow expected patterns" do
        check all ticket_attrs <- ticket_generator do
          {:ok, ticket} = Tickets.create_ticket(ticket_attrs)
          
          # Apply random status updates
          final_ticket = apply_random_status_updates(ticket)
          
          # Verify final state is valid
          assert final_ticket.status in [:open, :in_progress, :resolved, :closed, :discarded]
          
          # If closed or discarded, should have been through valid progression
          if final_ticket.status in [:closed, :discarded] do
            assert ticket.status not in [:closed, :discarded]  # Can't start as closed/discarded
          end
        end
      end
    end
        end
      end
    end
  end

  # Helper functions

  defp ticket_data_generator do
    gen all(
          title <- string(:alphanumeric, min_length: 1, max_length: 100),
          description <- string(:alphanumeric, min_length: 1, max_length: 500),
          priority <- member_of([:low, :medium, :high, :urgent]),
          assigned_to <- optional(string(:alphanumeric, min_length: 1, max_length: 50))
        ) do
      %{
        title: title,
        description: description,
        priority: priority,
        assigned_to: assigned_to
      }
    end
  end

defp apply_random_status_updates(ticket) do
    actions = [:assign, :resolve, :close, :discard]
    num_updates = Enum.random(0..3)
    
    Enum.reduce(1..num_updates, ticket, fn _, acc ->
      action = Enum.random(actions)
      apply_status_update(acc, action)
    end)
  end

  defp apply_status_update(ticket, :assign) do
    if ticket.status in [:open, :in_progress] do
      assigned_to = "User#{System.unique_integer()}"

      case Tickets.assign_ticket(ticket, assigned_to) do
        {:ok, updated} -> updated
        {:error, _} -> ticket
      end
    else
      ticket
    end
  end

  defp apply_status_update(ticket, :resolve) do
    if ticket.status in [:open, :in_progress] do
      case Tickets.resolve_ticket(ticket) do
        {:ok, updated} -> updated
        {:error, _} -> ticket
      end
    else
      ticket
    end
  end

  defp apply_status_update(ticket, :close) do
    if ticket.status != :closed do
      case Tickets.close_ticket(ticket) do
        {:ok, updated} -> updated
        {:error, _} -> ticket
      end
    else
      ticket
    end
  end

  defp apply_status_update(ticket, :discard) do
    if ticket.status != :discarded do
      case Tickets.discard_ticket(ticket) do
        {:ok, updated} -> updated
        {:error, _} -> ticket
      end
    else
      ticket
    end
  end

  defp is_valid_status_progression(from, to) do
    valid_transitions = %{
      :open => [:open, :in_progress, :closed],
      :in_progress => [:in_progress, :resolved, :closed],
      :resolved => [:resolved, :closed],
      :closed => [:closed]
    }

    to in Map.get(valid_transitions, from, [])
  end

  defp update_assigned_to_then_priority(ticket) do
    assigned_to = "User1"
    {:ok, ticket1} = Tickets.assign_ticket(ticket, assigned_to)

    new_priority =
      case ticket1.priority do
        :low -> :medium
        :medium -> :high
        :high -> :urgent
        :urgent -> :low
      end

    # Note: This would need a separate update_priority action in real implementation
    # For now, we'll simulate it
    {:ok, %{ticket1 | priority: new_priority}}
  end

  defp update_priority_then_assigned_to(ticket) do
    # Simulate priority update first
    new_priority =
      case ticket.priority do
        :low -> :medium
        :medium -> :high
        :high -> :urgent
        :urgent -> :low
      end

    ticket1 = %{ticket | priority: new_priority}

    assigned_to = "User1"
    {:ok, ticket2} = Tickets.assign_ticket(ticket1, assigned_to)
    ticket2
  end
end
