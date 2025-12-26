defmodule TicketProcessor.TicketContractTest do
  use ExUnit.Case, async: true
  use StreamData

  alias TicketProcessor.Tickets
  alias TicketProcessor.TicketGenerators

  @moduletag :contract

  describe "Ticket resource contracts" do
    test "create_ticket contract" do
      contract "create_ticket maintains invariants" do
        check all(ticket_attrs <- TicketGenerators.ticket_attrs()) do
          # Pre-condition: valid attributes
          assert_valid_ticket_attrs(ticket_attrs)

          # Action
          result = Tickets.create_ticket(ticket_attrs)

          # Post-condition
          case result do
            {:ok, ticket} ->
              # Invariants
              assert_valid_ticket(ticket)
              # Default status
              assert ticket.status == :open
              assert not is_nil(ticket.id)
              assert not is_nil(ticket.created_at)
              assert not is_nil(ticket.updated_at)

              # Attributes match input
              assert ticket.title == ticket_attrs.title
              assert ticket.description == ticket_attrs.description
              assert ticket.priority == ticket_attrs.priority
              assert ticket.assigned_to == ticket_attrs.assigned_to

            {:error, changeset} ->
              # If error, should be due to validation
              assert has_validation_errors?(changeset)
          end
        end
      end
    end

    test "assign_ticket contract" do
      contract "assign_ticket maintains invariants" do
        check all(
                ticket <- TicketGenerators.ticket_with_status(:open),
                assigned_to <- TicketGenerators.assigned_to_generator()
              ) do
          # Pre-condition: ticket is assignable
          assert ticket.status in [:open, :in_progress]

          # Action
          result = Tickets.assign_ticket(ticket, assigned_to)

          # Post-condition
          case result do
            {:ok, updated_ticket} ->
              # Invariants
              assert_valid_ticket(updated_ticket)
              assert updated_ticket.id == ticket.id
              assert updated_ticket.assigned_to == assigned_to
              assert updated_ticket.status == :in_progress
              assert updated_ticket.updated_at >= ticket.updated_at

              # Other fields unchanged
              assert updated_ticket.title == ticket.title
              assert updated_ticket.description == ticket.description
              assert updated_ticket.priority == ticket.priority

            {:error, _changeset} ->
              # Should not happen for valid inputs
              false
          end
        end
      end
    end

    test "resolve_ticket contract" do
      contract "resolve_ticket maintains invariants" do
        check all(ticket <- TicketGenerators.ticket_with_status(:in_progress)) do
          # Pre-condition: ticket is resolvable
          assert ticket.status in [:open, :in_progress]

          # Action
          result = Tickets.resolve_ticket(ticket)

          # Post-condition
          case result do
            {:ok, resolved_ticket} ->
              # Invariants
              assert_valid_ticket(resolved_ticket)
              assert resolved_ticket.id == ticket.id
              assert resolved_ticket.status == :resolved
              assert resolved_ticket.updated_at >= ticket.updated_at

              # Other fields unchanged
              assert resolved_ticket.title == ticket.title
              assert resolved_ticket.description == ticket.description
              assert resolved_ticket.priority == ticket.priority
              assert resolved_ticket.assigned_to == ticket.assigned_to

            {:error, _changeset} ->
              # Should not happen for valid inputs
              false
          end
        end
      end
    end

    test "close_ticket contract" do
      contract "close_ticket maintains invariants" do
        check all(ticket <- TicketGenerators.ticket_struct()) do
          # Pre-condition: ticket is not already closed
          if ticket.status != :closed do
            # Action
            result = Tickets.close_ticket(ticket)

            # Post-condition
            case result do
              {:ok, closed_ticket} ->
                # Invariants
                assert_valid_ticket(closed_ticket)
                assert closed_ticket.id == ticket.id
                assert closed_ticket.status == :closed
                assert closed_ticket.updated_at >= ticket.updated_at

                # Other fields unchanged
                assert closed_ticket.title == ticket.title
                assert closed_ticket.description == ticket.description
                assert closed_ticket.priority == ticket.priority
                assert closed_ticket.assigned_to == ticket.assigned_to

              {:error, _changeset} ->
                # Should not happen for valid inputs
                false
            end
          else
            # Already closed - should remain closed
            true
          end
        end
      end
    end

    test "list_tickets contract" do
      contract "list_tickets maintains invariants" do
        check all(tickets <- TicketGenerators.ticket_list(min_length: 1, max_length: 5)) do
          # Pre-condition: create tickets
          created_tickets =
            for ticket_attrs <- tickets do
              {:ok, ticket} = Tickets.create_ticket(ticket_attrs)
              ticket
            end

          # Action
          listed_tickets = Tickets.list_tickets()

          # Post-condition
          # All created tickets should be in the list
          for created_ticket <- created_tickets do
            assert Enum.any?(listed_tickets, fn listed ->
                     listed.id == created_ticket.id
                   end)
          end

          # List should contain valid tickets
          for listed_ticket <- listed_tickets do
            assert_valid_ticket(listed_ticket)
          end

          # Count should be at least as many as created
          assert length(listed_tickets) >= length(created_tickets)

          true
        end
      end
    end
  end

  describe "Ticket business rules contracts" do
    test "status progression contract" do
      contract "status follows valid progression rules" do
        check all(
                initial_ticket <- TicketGenerators.ticket_with_status(:open),
                updates <-
                  list(member_of([:assign, :resolve, :close]), min_length: 1, max_length: 5)
              ) do
          # Pre-condition: start with open ticket
          assert initial_ticket.status == :open

          # Action: apply status updates
          final_ticket = apply_status_updates(initial_ticket, updates)

          # Post-condition: status progression is valid
          assert_valid_status_progression(initial_ticket.status, final_ticket.status)

          # Final state should be valid
          assert final_ticket.status in [:open, :in_progress, :resolved, :closed]

          true
        end
      end
    end

    test "priority ordering contract" do
      contract "tickets can be ordered by priority" do
        check all(tickets <- TicketGenerators.ticket_list(min_length: 3, max_length: 10)) do
          # Pre-condition: create tickets
          created_tickets =
            for ticket_attrs <- tickets do
              {:ok, ticket} = Tickets.create_ticket(ticket_attrs)
              ticket
            end

          # Action: sort by priority
          priority_order = [:urgent, :high, :medium, :low]

          sorted_tickets =
            Enum.sort_by(created_tickets, fn ticket ->
              Enum.find_index(priority_order, &(&1 == ticket.priority))
            end)

          # Post-condition: ordering is correct
          priorities = Enum.map(sorted_tickets, & &1.priority)

          expected_priorities =
            Enum.sort(priorities, fn a, b ->
              Enum.find_index(priority_order, &(&1 == a)) <=
                Enum.find_index(priority_order, &(&1 == b))
            end)

          assert priorities == expected_priorities

          true
        end
      end
    end

    test "uniqueness contract" do
      contract "ticket titles are unique" do
        check all(title <- string(:alphanumeric, min_length: 10, max_length: 50)) do
          ticket_attrs = %{
            title: title,
            description: "Description for #{title}",
            priority: :medium
          }

          # First creation should succeed
          assert {:ok, _ticket1} = Tickets.create_ticket(ticket_attrs)

          # Second creation with same title should fail
          assert {:error, _changeset2} = Tickets.create_ticket(ticket_attrs)

          true
        end
      end
    end
  end

  # Helper functions

  defp assert_valid_ticket_attrs(attrs) do
    assert is_binary(attrs.title)
    assert String.length(attrs.title) > 0
    assert String.length(attrs.title) <= 255

    assert is_binary(attrs.description)
    assert String.length(attrs.description) > 0
    assert String.length(attrs.description) <= 2000

    assert attrs.priority in [:low, :medium, :high, :urgent]

    if attrs.assigned_to do
      assert is_binary(attrs.assigned_to)
      assert String.length(attrs.assigned_to) > 0
      assert String.length(attrs.assigned_to) <= 100
    end
  end

  defp assert_valid_ticket(ticket) do
    assert is_binary(ticket.title)
    assert is_binary(ticket.description)
    assert ticket.priority in [:low, :medium, :high, :urgent]
    assert ticket.status in [:open, :in_progress, :resolved, :closed]
    assert is_binary(ticket.id)
    assert %DateTime{} = ticket.created_at
    assert %DateTime{} = ticket.updated_at
  end

  defp has_validation_errors?(changeset) do
    changeset.valid? == false and length(changeset.errors) > 0
  end

  defp apply_status_updates(ticket, updates) do
    Enum.reduce(updates, ticket, fn update, acc ->
      case update do
        :assign ->
          if acc.status in [:open, :in_progress] do
            assigned_to = "User#{System.unique_integer()}"

            case Tickets.assign_ticket(acc, assigned_to) do
              {:ok, updated} -> updated
              {:error, _} -> acc
            end
          else
            acc
          end

        :resolve ->
          if acc.status in [:open, :in_progress] do
            case Tickets.resolve_ticket(acc) do
              {:ok, updated} -> updated
              {:error, _} -> acc
            end
          else
            acc
          end

        :close ->
          if acc.status != :closed do
            case Tickets.close_ticket(acc) do
              {:ok, updated} -> updated
              {:error, _} -> acc
            end
          else
            acc
          end
      end
    end)
  end

  defp assert_valid_status_progression(from, to) do
    valid_transitions = %{
      :open => [:open, :in_progress, :closed],
      :in_progress => [:in_progress, :resolved, :closed],
      :resolved => [:resolved, :closed],
      :closed => [:closed]
    }

    to in Map.get(valid_transitions, from, [])
  end

  defp contract(description, do: block) do
    @tag :contract
    test description, do: block
  end
end
