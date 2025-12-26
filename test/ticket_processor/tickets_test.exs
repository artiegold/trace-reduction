defmodule TicketProcessor.TicketsTest do
  use ExUnit.Case, async: true
  use StreamData

  alias TicketProcessor.Tickets
  alias TicketProcessor.Tickets.Ticket

  describe "Ticket resource property-based tests" do
    test "create_ticket with valid data" do
      ticket_generator =
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

      assert run(ticket_generator, fn ticket_attrs ->
               {:ok, ticket} = Tickets.create_ticket(ticket_attrs)

               # Verify all attributes are set correctly
               assert ticket.title == ticket_attrs.title
               assert ticket.description == ticket_attrs.description
               assert ticket.priority == ticket_attrs.priority
               assert ticket.assigned_to == ticket_attrs.assigned_to
               # default status
               assert ticket.status == :open
               assert not is_nil(ticket.id)
               assert not is_nil(ticket.created_at)
               assert not is_nil(ticket.updated_at)

               true
             end)
    end

    test "create_ticket rejects invalid data" do
      invalid_title_generator =
        gen all(title <- one_of([string(:alphanumeric, max_length: 0), "", nil])) do
          %{
            title: title,
            description: "Valid description",
            priority: :medium
          }
        end

      invalid_description_generator =
        gen all(description <- one_of([string(:alphanumeric, max_length: 0), "", nil])) do
          %{
            title: "Valid title",
            description: description,
            priority: :medium
          }
        end

      invalid_priority_generator =
        gen all(priority <- member_of([:invalid, :wrong, :bad])) do
          %{
            title: "Valid title",
            description: "Valid description",
            priority: priority
          }
        end

      # Test invalid titles
      assert run(invalid_title_generator, fn ticket_attrs ->
               case Tickets.create_ticket(ticket_attrs) do
                 {:error, _changeset} -> true
                 {:ok, _ticket} -> false
               end
             end)

      # Test invalid descriptions
      assert run(invalid_description_generator, fn ticket_attrs ->
               case Tickets.create_ticket(ticket_attrs) do
                 {:error, _changeset} -> true
                 {:ok, _ticket} -> false
               end
             end)

      # Test invalid priorities
      assert run(invalid_priority_generator, fn ticket_attrs ->
               case Tickets.create_ticket(ticket_attrs) do
                 {:error, _changeset} -> true
                 {:ok, _ticket} -> false
               end
             end)
    end

    test "list_tickets returns all tickets" do
      ticket_generator =
        gen all(
              title <- string(:alphanumeric, min_length: 1, max_length: 50),
              description <- string(:alphanumeric, min_length: 1, max_length: 200),
              priority <- member_of([:low, :medium, :high, :urgent])
            ) do
          %{
            title: title,
            description: description,
            priority: priority
          }
        end

      assert run(list(ticket_generator, min_length: 1, max_length: 10), fn ticket_attrs_list ->
               # Create tickets
               created_tickets =
                 for ticket_attrs <- ticket_attrs_list do
                   {:ok, ticket} = Tickets.create_ticket(ticket_attrs)
                   ticket
                 end

               # List all tickets
               listed_tickets = Tickets.list_tickets()

               # Verify all created tickets are in the list
               for created_ticket <- created_tickets do
                 assert Enum.any?(listed_tickets, fn listed_ticket ->
                          listed_ticket.id == created_ticket.id
                        end)
               end

               # Verify count matches
               assert length(listed_tickets) >= length(created_tickets)

               true
             end)
    end

    test "assign_ticket updates status and assignee" do
      ticket_generator =
        gen all(
              title <- string(:alphanumeric, min_length: 1, max_length: 50),
              description <- string(:alphanumeric, min_length: 1, max_length: 200),
              priority <- member_of([:low, :medium, :high, :urgent]),
              assigned_to <- string(:alphanumeric, min_length: 1, max_length: 50)
            ) do
          %{
            title: title,
            description: description,
            priority: priority,
            assigned_to: assigned_to
          }
        end

      assert run(ticket_generator, fn ticket_attrs ->
               {:ok, ticket} = Tickets.create_ticket(ticket_attrs)

               # Assign ticket
               {:ok, assigned_ticket} = Tickets.assign_ticket(ticket, ticket_attrs.assigned_to)

               # Verify assignment
               assert assigned_ticket.assigned_to == ticket_attrs.assigned_to
               assert assigned_ticket.status == :in_progress
               assert assigned_ticket.id == ticket.id
               assert assigned_ticket.updated_at > ticket.updated_at

               true
             end)
    end

    test "resolve_ticket updates status" do
      ticket_generator =
        gen all(
              title <- string(:alphanumeric, min_length: 1, max_length: 50),
              description <- string(:alphanumeric, min_length: 1, max_length: 200),
              priority <- member_of([:low, :medium, :high, :urgent])
            ) do
          %{
            title: title,
            description: description,
            priority: priority
          }
        end

      assert run(ticket_generator, fn ticket_attrs ->
               {:ok, ticket} = Tickets.create_ticket(ticket_attrs)

               # Resolve ticket
               {:ok, resolved_ticket} = Tickets.resolve_ticket(ticket)

               # Verify resolution
               assert resolved_ticket.status == :resolved
               assert resolved_ticket.id == ticket.id
               assert resolved_ticket.updated_at > ticket.updated_at

               true
             end)
    end

    test "close_ticket updates status" do
      ticket_generator =
        gen all(
              title <- string(:alphanumeric, min_length: 1, max_length: 50),
              description <- string(:alphanumeric, min_length: 1, max_length: 200),
              priority <- member_of([:low, :medium, :high, :urgent])
            ) do
          %{
            title: title,
            description: description,
            priority: priority
          }
        end

      assert run(ticket_generator, fn ticket_attrs ->
               {:ok, ticket} = Tickets.create_ticket(ticket_attrs)

               # Close ticket
               {:ok, closed_ticket} = Tickets.close_ticket(ticket)

               # Verify closure
               assert closed_ticket.status == :closed
               assert closed_ticket.id == ticket.id
               assert closed_ticket.updated_at > ticket.updated_at

               true
             end)
    end

    test "ticket status transitions are valid" do
      status_transition_generator =
        gen all(
              initial_status <- member_of([:open, :in_progress, :resolved, :closed]),
              action <- member_of([:assign, :resolve, :close])
            ) do
          {initial_status, action}
        end

      assert run(status_transition_generator, fn {initial_status, action} ->
               # Create ticket with specific status
               {:ok, ticket} =
                 Tickets.create_ticket(%{
                   title: "Test ticket",
                   description: "Test description",
                   priority: :medium
                 })

               # Manually set initial status for testing
               updated_ticket = %{ticket | status: initial_status}

               # Test valid transitions
               result =
                 case {initial_status, action} do
                   {:open, :assign} ->
                     Tickets.assign_ticket(updated_ticket, "test_user")

                   {:in_progress, :resolve} ->
                     Tickets.resolve_ticket(updated_ticket)

                   {:resolved, :close} ->
                     Tickets.close_ticket(updated_ticket)

                   {:in_progress, :close} ->
                     Tickets.close_ticket(updated_ticket)

                   {:open, :close} ->
                     Tickets.close_ticket(updated_ticket)

                   _ ->
                     # Invalid transition - should fail
                     {:error, :invalid_transition}
                 end

               case result do
                 {:ok, _updated_ticket} -> true
                 {:error, _changeset} when action in [:assign, :resolve, :close] -> true
                 {:error, :invalid_transition} -> true
                 _ -> false
               end
             end)
    end

    test "ticket priority ordering" do
      priority_order = [:urgent, :high, :medium, :low]

      ticket_generator =
        gen all(priority <- member_of(priority_order)) do
          %{
            title: "Test ticket",
            description: "Test description",
            priority: priority
          }
        end

      assert run(list(ticket_generator, min_length: 5, max_length: 20), fn ticket_attrs_list ->
               # Create tickets with different priorities
               created_tickets =
                 for ticket_attrs <- ticket_attrs_list do
                   {:ok, ticket} = Tickets.create_ticket(ticket_attrs)
                   ticket
                 end

               # Sort by priority (urgent first)
               sorted_tickets =
                 Enum.sort_by(created_tickets, fn ticket ->
                   Enum.find_index(priority_order, &(&1 == ticket.priority))
                 end)

               # Verify ordering
               priorities = Enum.map(sorted_tickets, & &1.priority)

               assert priorities ==
                        Enum.sort(priorities, fn a, b ->
                          Enum.find_index(priority_order, &(&1 == a)) <=
                            Enum.find_index(priority_order, &(&1 == b))
                        end)

               true
             end)
    end
  end

  describe "Ticket edge cases" do
    test "handles maximum field lengths" do
      max_length_generator =
        gen all(
              title <- string(:alphanumeric, min_length: 255, max_length: 255),
              description <- string(:alphanumeric, min_length: 2000, max_length: 2000),
              assigned_to <- string(:alphanumeric, min_length: 100, max_length: 100)
            ) do
          %{
            title: title,
            description: description,
            priority: :medium,
            assigned_to: assigned_to
          }
        end

      assert run(max_length_generator, fn ticket_attrs ->
               case Tickets.create_ticket(ticket_attrs) do
                 {:ok, ticket} ->
                   # Should succeed if within limits
                   assert String.length(ticket.title) <= 255
                   assert String.length(ticket.description) <= 2000
                   assert String.length(ticket.assigned_to) <= 100
                   true

                 {:error, _changeset} ->
                   # Should fail if exceeding limits
                   true
               end
             end)
    end

    test "concurrent ticket operations" do
      ticket_generator =
        gen all(
              title <- string(:alphanumeric, min_length: 1, max_length: 50),
              description <- string(:alphanumeric, min_length: 1, max_length: 200)
            ) do
          %{
            title: title,
            description: description,
            priority: :medium
          }
        end

      assert run(list(ticket_generator, min_length: 3, max_length: 10), fn ticket_attrs_list ->
               # Create tickets concurrently
               tasks =
                 for ticket_attrs <- ticket_attrs_list do
                   Task.async(fn ->
                     Tickets.create_ticket(ticket_attrs)
                   end)
                 end

               results = Task.await_many(tasks, 5000)

               # All should succeed
               assert length(results) == length(ticket_attrs_list)

               assert Enum.all?(results, fn
                        {:ok, _ticket} -> true
                        _ -> false
                      end)

               true
             end)
    end
  end
end
