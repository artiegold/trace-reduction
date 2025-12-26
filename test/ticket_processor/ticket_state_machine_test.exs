defmodule TicketProcessor.TicketStateMachineTest do
  use ExUnit.Case, async: true
  use StreamData

  alias TicketProcessor.Tickets
  alias TicketProcessor.TicketGenerators

  @moduletag :state_machine

  describe "Ticket state machine properties" do
    test "state transition matrix" do
      # Define valid state transitions
      transitions = %{
        :open => [:open, :in_progress, :closed, :discarded],
        :in_progress => [:in_progress, :resolved, :closed, :discarded],
        :resolved => [:resolved, :closed, :discarded],
        :closed => [:closed],
        :discarded => [:discarded]
      }

      property "all state transitions follow the defined matrix" do
        check all(
                initial_ticket <- TicketGenerators.ticket_with_status(:open),
                transition_sequence <- transition_sequence_generator()
              ) do
          final_ticket = apply_transition_sequence(initial_ticket, transition_sequence)

          # Verify the final state is reachable
          assert is_reachable_state(:open, final_ticket.status, transitions)

          # Verify each transition in the sequence was valid
          assert valid_transition_sequence?(initial_ticket, transition_sequence, transitions)

          true
        end
      end
    end

    test "state machine invariants" do
      property "state machine maintains invariants across all transitions" do
        check all(
                ticket <- TicketGenerators.ticket_struct(),
                transition_sequence <- transition_sequence_generator()
              ) do
          # Apply transitions
          final_ticket = apply_transition_sequence(ticket, transition_sequence)

          # Invariant 1: Closed tickets cannot be modified
          if final_ticket.status == :closed do
            # Attempting further transitions should fail or be no-ops
            assert closed_ticket_immutable?(final_ticket)
          end

          # Invariant 2: Status progression is monotonic (in terms of completion)
          assert monotonic_progression?(ticket.status, final_ticket.status)

          # Invariant 3: Ticket identity is preserved
          assert final_ticket.id == ticket.id

          # Invariant 4: Timestamps are non-decreasing
          assert final_ticket.updated_at >= ticket.updated_at

          true
        end
      end
    end

    test "state machine coverage" do
      property "all possible states are reachable" do
        check all(
                initial_ticket <- TicketGenerators.ticket_with_status(:open),
                max_transitions <- integer(0, 10)
              ) do
          # Generate random transition sequences
          transition_sequences =
            for _ <- 1..100 do
              generate_transition_sequence(max_transitions)
            end

          # Apply all sequences and collect final states
          reachable_states =
            for sequence <- transition_sequences do
              final_ticket = apply_transition_sequence(initial_ticket, sequence)
              final_ticket.status
            end

          # All states should be reachable from open
          expected_states = [:open, :in_progress, :resolved, :closed]
          reachable_set = Enum.uniq(reachable_states)

          # At minimum, we should be able to reach closed state
          assert :closed in reachable_set

          # Ideally, we should reach all states
          coverage_ratio = length(reachable_set) / length(expected_states)
          # At least 75% coverage
          assert coverage_ratio >= 0.75

          true
        end
      end
    end

    test "state machine determinism" do
      property "same transition sequence yields same final state" do
        check all(
                initial_ticket <- TicketGenerators.ticket_with_status(:open),
                transition_sequence <- transition_sequence_generator()
              ) do
          # Apply the same sequence twice
          final_ticket1 = apply_transition_sequence(initial_ticket, transition_sequence)
          final_ticket2 = apply_transition_sequence(initial_ticket, transition_sequence)

          # Should end up in identical state
          assert final_ticket1.status == final_ticket2.status
          assert final_ticket1.assigned_to == final_ticket2.assigned_to
          assert final_ticket1.priority == final_ticket2.priority

          true
        end
      end
    end

    test "state machine convergence" do
      property "different paths can converge to same state" do
        check all(initial_ticket <- TicketGenerators.ticket_with_status(:open)) do
          # Path 1: assign -> resolve -> close
          path1 = [:assign, :resolve, :close]
          final1 = apply_transition_sequence(initial_ticket, path1)

          # Path 2: assign -> close
          path2 = [:assign, :close]
          final2 = apply_transition_sequence(initial_ticket, path2)

          # Both should end in closed state
          assert final1.status == :closed
          assert final2.status == :closed

          true
        end
      end
    end
  end

  describe "State machine edge cases" do
    test "invalid transitions are rejected" do
      invalid_transitions = [
        # Can't assign resolved ticket
        {:resolved, :assign},
        # Can't assign closed ticket
        {:closed, :assign},
        # Can't resolve closed ticket
        {:closed, :resolve},
        # Can't go back to in_progress
        {:resolved, :in_progress},
        # Can't assign discarded ticket
        {:discarded, :assign},
        # Can't resolve discarded ticket
        {:discarded, :resolve},
        # Can't go back to in_progress
        {:discarded, :in_progress}
      ]

      property "invalid transitions are properly rejected" do
        check all(
                {from_state, action} <- member_of(invalid_transitions),
                ticket <- TicketGenerators.ticket_with_status(from_state)
              ) do
          result = apply_transition(ticket, action)

          case result do
            {:error, _changeset} -> true
            # Should not succeed
            {:ok, _updated_ticket} -> false
          end
        end
      end
    end

    test "state machine handles concurrent transitions" do
      property "concurrent state updates are handled safely" do
        check all(
                initial_ticket <- TicketGenerators.ticket_with_status(:open),
                num_concurrent <- integer(2, 5)
              ) do
          # Create concurrent tasks for the same ticket
          tasks =
            for _ <- 1..num_concurrent do
              Task.async(fn ->
                # Random transition
                action = Enum.random([:assign, :resolve, :close])
                apply_transition(initial_ticket, action)
              end)
            end

          results = Task.await_many(tasks, 5000)

          # At most one should succeed if they conflict
          successful_results =
            Enum.filter(results, fn
              {:ok, _} -> true
              _ -> false
            end)

          assert length(successful_results) <= 1

          # All results should be either success or error
          assert Enum.all?(results, fn
                   {:ok, _} -> true
                   {:error, _} -> true
                   _ -> false
                 end)

          true
        end
      end
    end
  end

  # Helper functions

  defp transition_sequence_generator do
    list(member_of([:assign, :resolve, :close]), min_length: 0, max_length: 5)
  end

  defp generate_transition_sequence(max_length) do
    num_transitions = Enum.random(0..max_length)
    for _ <- 1..num_transitions, do: Enum.random([:assign, :resolve, :close])
  end

  defp apply_transition_sequence(ticket, transitions) do
    Enum.reduce(transitions, ticket, fn transition, acc ->
      apply_transition(acc, transition)
    end)
  end

  defp apply_transition(ticket, :assign) do
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

  defp apply_transition(ticket, :resolve) do
    if ticket.status in [:open, :in_progress] do
      case Tickets.resolve_ticket(ticket) do
        {:ok, updated} -> updated
        {:error, _} -> ticket
      end
    else
      ticket
    end
  end

  defp apply_transition(ticket, :close) do
    if ticket.status != :closed do
      case Tickets.close_ticket(ticket) do
        {:ok, updated} -> updated
        {:error, _} -> ticket
      end
    else
      ticket
    end
  end

  defp is_reachable_state(from, to, transitions) do
    # Simple BFS to check reachability
    queue = [from]
    visited = MapSet.new([from])

    reachable = bfs_reachability(queue, visited, transitions, MapSet.new())
    to in reachable
  end

  defp bfs_reachability([], _visited, _transitions, reachable), do: reachable

  defp bfs_reachability([current | rest], visited, transitions, reachable) do
    next_states = Map.get(transitions, current, [])
    new_reachable = MapSet.union(reachable, MapSet.new(next_states))

    unvisited =
      Enum.filter(next_states, fn state ->
        not MapSet.member?(visited, state)
      end)

    new_visited =
      Enum.reduce(unvisited, visited, fn state, acc ->
        MapSet.put(acc, state)
      end)

    bfs_reachability(rest ++ unvisited, new_visited, transitions, new_reachable)
  end

  defp valid_transition_sequence?(initial_ticket, transitions, transition_matrix) do
    {_, valid?} =
      Enum.reduce(transitions, {initial_ticket.status, true}, fn
        transition, {current_status, acc} ->
          next_states = Map.get(transition_matrix, current_status, [])
          new_valid = acc and transition in next_states

          # Simulate the status change for next iteration
          new_status =
            case transition do
              :assign when current_status in [:open, :in_progress] -> :in_progress
              :resolve when current_status in [:open, :in_progress] -> :resolved
              :close when current_status != :closed -> :closed
              _ -> current_status
            end

          {new_status, new_valid}
      end)

    valid?
  end

  defp closed_ticket_immutable?(ticket) do
    # Try all transitions on closed ticket
    results = [
      apply_transition(ticket, :assign),
      apply_transition(ticket, :resolve),
      apply_transition(ticket, :close)
    ]

    # All should either fail or return the same ticket
    Enum.all?(results, fn
      {:error, _} -> true
      {:ok, updated} -> updated.status == :closed
      _ -> false
    end)
  end

  defp monotonic_progression?(from, to) do
    # Define completion levels
    completion_levels = %{
      :open => 0,
      :in_progress => 1,
      :resolved => 2,
      :closed => 3
    }

    from_level = Map.get(completion_levels, from, 0)
    to_level = Map.get(completion_levels, to, 0)

    # Can only stay same or increase completion level
    to_level >= from_level
  end
end
