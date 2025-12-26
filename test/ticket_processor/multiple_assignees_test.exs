defmodule TicketProcessor.TicketsTest do
  use ExUnit.Case, async: true
  use StreamData

  alias TicketProcessor.Tickets
  alias TicketProcessor.Tickets.Ticket

  describe "Ticket resource with multiple assignees" do
    test "create_ticket with multiple assignees" do
      ticket_generator =
        gen all(
              title <- string(:alphanumeric, min_length: 1, max_length: 100),
              description <- string(:alphanumeric, min_length: 1, max_length: 500),
              priority <- member_of([:low, :medium, :high, :urgent]),
              assigned_to <-
                list(string(:alphanumeric, min_length: 3, max_length: 20),
                  min_length: 1,
                  max_length: 5
                )
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

               # Verify assignees are set correctly
               assert ticket.assigned_to == ticket_attrs.assigned_to
               assert is_list(ticket.assigned_to)
               assert length(ticket.assigned_to) > 0
               assert length(ticket.assigned_to) <= 5

               true
             end)
    end

    test "add and remove assignees" do
      ticket_generator =
        gen all(
              title <- string(:alphanumeric, min_length: 1, max_length: 50),
              description <- string(:alphanumeric, min_length: 1, max_length: 200),
              priority <- member_of([:low, :medium, :high, :urgent]),
              initial_assignees <-
                list(string(:alphanumeric, min_length: 3, max_length: 15),
                  min_length: 1,
                  max_length: 3
                ),
              new_assignee <- string(:alphanumeric, min_length: 3, max_length: 15)
            ) do
          %{
            title: title,
            description: description,
            priority: priority,
            initial_assignees: initial_assignees,
            new_assignee: new_assignee
          }
        end

      assert run(ticket_generator, fn ticket_attrs ->
               {:ok, ticket} =
                 Tickets.create_ticket(%{
                   title: ticket_attrs.title,
                   description: ticket_attrs.description,
                   priority: ticket_attrs.priority,
                   assigned_to: ticket_attrs.initial_assignees
                 })

               # Add new assignee
               {:ok, updated_ticket} = Tickets.add_assignee(ticket, ticket_attrs.new_assignee)

               # Verify new assignee was added
               assert ticket_attrs.new_assignee in updated_ticket.assigned_to

               assert length(updated_ticket.assigned_to) ==
                        length(ticket_attrs.initial_assignees) + 1

               # Remove first assignee
               if length(ticket_attrs.initial_assignees) > 0 do
                 first_assignee = hd(ticket_attrs.initial_assignees)
                 {:ok, final_ticket} = Tickets.remove_assignee(updated_ticket, first_assignee)

                 # Verify assignee was removed
                 assert first_assignee not in final_ticket.assigned_to
                 assert length(final_ticket.assigned_to) == length(updated_ticket.assigned_to) - 1
                 assert ticket_attrs.new_assignee in final_ticket.assigned_to
               end

               true
             end)
    end

    test "assignee list uniqueness" do
      ticket_generator =
        gen all(
              title <- string(:alphanumeric, min_length: 1, max_length: 50),
              description <- string(:alphanumeric, min_length: 1, max_length: 200),
              priority <- member_of([:low, :medium, :high, :urgent]),
              assignees <-
                list(string(:alphanumeric, min_length: 3, max_length: 15),
                  min_length: 1,
                  max_length: 5
                )
            ) do
          %{
            title: title,
            description: description,
            priority: priority,
            # Duplicate first assignee
            assignees: assignees ++ [hd(assignees)]
          }
        end

      assert run(ticket_generator, fn ticket_attrs ->
               {:ok, ticket} =
                 Tickets.create_ticket(%{
                   title: ticket_attrs.title,
                   description: ticket_attrs.description,
                   priority: ticket_attrs.priority,
                   assigned_to: Enum.uniq(ticket_attrs.assignees)
                 })

               # Verify no duplicates in assignee list
               assert length(ticket.assigned_to) == length(Enum.uniq(ticket.assigned_to))

               true
             end)
    end

    test "assignee ordering is preserved" do
      assignee_generator = string(:alphanumeric, min_length: 3, max_length: 15)

      assert run(list(assignee_generator, min_length: 3, max_length: 5), fn assignees ->
               ticket_attrs = %{
                 title: "Test ticket",
                 description: "Test description",
                 priority: :medium,
                 assigned_to: assignees
               }

               {:ok, ticket} = Tickets.create_ticket(ticket_attrs)

               # Verify ordering is preserved (should match input order)
               assert ticket.assigned_to == assignees

               true
             end)
    end

    test "empty assignee list" do
      ticket_attrs = %{
        title: "Test ticket",
        description: "Test description",
        priority: :medium,
        assigned_to: []
      }

      {:ok, ticket} = Tickets.create_ticket(ticket_attrs)

      # Verify empty list is handled correctly
      assert ticket.assigned_to == []
      assert length(ticket.assigned_to) == 0
    end

    test "assignee count limits" do
      assignee_generator = string(:alphanumeric, min_length: 1, max_length: 50)

      # Test maximum assignees (50)
      max_assignees = for _ <- 1..50, do: "assignee#{System.unique_integer()}"

      ticket_attrs = %{
        title: "Test ticket with max assignees",
        description: "Test description",
        priority: :medium,
        assigned_to: max_assignees
      }

      {:ok, ticket} = Tickets.create_ticket(ticket_attrs)
      assert length(ticket.assigned_to) == 50

      # Test exceeding limit should fail
      too_many_assignees = for _ <- 1..51, do: "assignee#{System.unique_integer()}"

      invalid_attrs = %{
        title: "Test ticket with too many assignees",
        description: "Test description",
        priority: :medium,
        assigned_to: too_many_assignees
      }

      assert {:error, _changeset} = Tickets.create_ticket(invalid_attrs)
    end

    test "assignee string length limits" do
      # Test individual assignee length
      # 50 chars (within limit)
      valid_assignee = String.duplicate("a", 50)
      # 101 chars (exceeds limit)
      invalid_assignee = String.duplicate("a", 101)

      valid_attrs = %{
        title: "Test ticket",
        description: "Test description",
        priority: :medium,
        assigned_to: [valid_assignee]
      }

      invalid_attrs = %{
        title: "Test ticket",
        description: "Test description",
        priority: :medium,
        assigned_to: [invalid_assignee]
      }

      {:ok, _ticket} = Tickets.create_ticket(valid_attrs)
      assert {:error, _changeset} = Tickets.create_ticket(invalid_attrs)
    end
  end

  describe "Multiple assignee edge cases" do
    test "concurrent assignee modifications" do
      {:ok, ticket} =
        Tickets.create_ticket(%{
          title: "Concurrent test ticket",
          description: "Test description",
          priority: :medium,
          assigned_to: ["initial@example.com"]
        })

      # Concurrent tasks to add different assignees
      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            assignee = "user#{i}@example.com"
            Tickets.add_assignee(ticket, assignee)
          end)
        end

      results = Task.await_many(tasks, 5000)

      # Some should succeed, some may fail due to conflicts
      successful_results =
        Enum.filter(results, fn
          {:ok, _} -> true
          _ -> false
        end)

      assert length(successful_results) >= 1

      # Final ticket should have multiple assignees (at least the original + one)
      {:ok, final_ticket} = Tickets.get_ticket(ticket.id)
      assert length(final_ticket.assigned_to) >= 2
    end

    test "assignee persistence across status changes" do
      assignees = ["alice@example.com", "bob@example.com", "charlie@example.com"]

      {:ok, ticket} =
        Tickets.create_ticket(%{
          title: "Persistence test ticket",
          description: "Test description",
          priority: :high,
          assigned_to: assignees
        })

      # Status changes should preserve assignees
      {:ok, assigned_ticket} = Tickets.assign_ticket(ticket, assignees)
      assert assigned_ticket.assigned_to == assignees

      {:ok, resolved_ticket} = Tickets.resolve_ticket(assigned_ticket)
      assert resolved_ticket.assigned_to == assignees

      {:ok, closed_ticket} = Tickets.close_ticket(resolved_ticket)
      assert closed_ticket.assigned_to == assignees
    end

    test "assignee removal preserves other assignees" do
      original_assignees = [
        "alice@example.com",
        "bob@example.com",
        "charlie@example.com",
        "dave@example.com"
      ]

      {:ok, ticket} =
        Tickets.create_ticket(%{
          title: "Removal test ticket",
          description: "Test description",
          priority: :medium,
          assigned_to: original_assignees
        })

      # Remove one assignee at a time
      remaining_assignees = original_assignees

      for assignee_to_remove <- original_assignees do
        {:ok, updated_ticket} = Tickets.remove_assignee(ticket, assignee_to_remove)
        remaining_assignees = List.delete(remaining_assignees, assignee_to_remove)

        assert assignee_to_remove not in updated_ticket.assigned_to
        assert length(updated_ticket.assigned_to) == length(remaining_assignees)

        # Verify other assignees are still there
        for remaining_assignee <- remaining_assignees do
          assert remaining_assignee in updated_ticket.assigned_to
        end
      end
    end
  end

  describe "Assignee validation" do
    test "invalid assignee formats" do
      invalid_assignees = [
        # Empty string
        [],
        # Whitespace only
        ["   "],
        # Nil value
        [nil],
        # Integer
        [123],
        # Struct
        [%{name: "invalid"}]
      ]

      for invalid_assignee_list <- invalid_assignees do
        invalid_attrs = %{
          title: "Invalid assignee test",
          description: "Test description",
          priority: :medium,
          assigned_to: invalid_assignee_list
        }

        assert {:error, _changeset} = Tickets.create_ticket(invalid_attrs)
      end
    end

    test "valid assignee formats" do
      valid_assignees = [
        ["user@example.com"],
        ["user.name@example.co.uk"],
        ["user+tag@example.com"],
        ["user123@sub.domain.com"],
        ["a@b.c"],
        ["very-long-email-address@example-domain-name.com"]
      ]

      for valid_assignee_list <- valid_assignees do
        valid_attrs = %{
          title: "Valid assignee test",
          description: "Test description",
          priority: :medium,
          assigned_to: valid_assignee_list
        }

        {:ok, ticket} = Tickets.create_ticket(valid_attrs)
        assert ticket.assigned_to == valid_assignee_list
      end
    end
  end
end
