defmodule TicketProcessor.TicketGenerators do
  @moduledoc """
  StreamData generators for testing Ticket resources.
  """

  use StreamData

  alias TicketProcessor.Tickets.Ticket

  @doc """
  Generates valid ticket attributes.
  """
  def ticket_attrs(opts \\ []) do
    gen all(
          title <- title_generator(opts),
          description <- description_generator(opts),
          priority <- priority_generator(),
          assigned_to <- optional(assigned_to_generator(opts))
        ) do
      %{
        title: title,
        description: description,
        priority: priority,
        assigned_to: assigned_to
      }
    end
  end

  @doc """
  Generates complete ticket structs.
  """
  def ticket_struct(opts \\ []) do
    gen all(
          attrs <- ticket_attrs(opts),
          id <- UUID.generator(),
          status <- status_generator(),
          created_at <- datetime_generator(),
          updated_at <- datetime_generator()
        ) do
      struct!(
        Ticket,
        Map.merge(attrs, %{
          id: id,
          status: status,
          created_at: created_at,
          updated_at: updated_at
        })
      )
    end
  end

  @doc """
  Generates lists of tickets.
  """
  def ticket_list(opts \\ []) do
    min_length = Keyword.get(opts, :min_length, 1)
    max_length = Keyword.get(opts, :max_length, 10)

    list(ticket_struct(opts), min_length: min_length, max_length: max_length)
  end

  @doc """
  Generates tickets with specific status.
  """
  def ticket_with_status(status) when status in [:open, :in_progress, :resolved, :closed] do
    gen all(
          attrs <- ticket_attrs(),
          id <- UUID.generator(),
          created_at <- datetime_generator(),
          updated_at <- datetime_generator()
        ) do
      struct!(
        Ticket,
        Map.merge(attrs, %{
          id: id,
          status: status,
          created_at: created_at,
          updated_at: updated_at
        })
      )
    end
  end

  @doc """
  Generates tickets with specific priority.
  """
  def ticket_with_priority(priority) when priority in [:low, :medium, :high, :urgent] do
    gen all(
          attrs <- ticket_attrs(),
          id <- UUID.generator(),
          status <- status_generator(),
          created_at <- datetime_generator(),
          updated_at <- datetime_generator()
        ) do
      struct!(
        Ticket,
        Map.merge(attrs, %{
          id: id,
          priority: priority,
          status: status,
          created_at: created_at,
          updated_at: updated_at
        })
      )
    end
  end

  @doc """
  Generates invalid ticket attributes for testing error cases.
  """
  def invalid_ticket_attrs do
    one_of([
      # Missing title
      map(ticket_attrs(), &Map.delete(&1, :title)),

      # Empty title
      map(ticket_attrs(), fn attrs -> %{attrs | title: ""} end),

      # Missing description
      map(ticket_attrs(), &Map.delete(&1, :description)),

      # Empty description
      map(ticket_attrs(), fn attrs -> %{attrs | description: ""} end),

      # Invalid priority
      map(ticket_attrs(), fn attrs -> %{attrs | priority: :invalid} end),

      # Nil priority
      map(ticket_attrs(), fn attrs -> %{attrs | priority: nil} end),

      # Title too long
      map(ticket_attrs(), fn attrs ->
        %{attrs | title: String.duplicate("a", 256)}
      end),

      # Description too long
      map(ticket_attrs(), fn attrs ->
        %{attrs | description: String.duplicate("a", 2001)}
      end),

# Too many assignees
      map(ticket_attrs(), fn attrs -> 
        %{attrs | assigned_to: List.duplicate("assignee", 51)}
      end)
      
      # Invalid assignee (too long)
      map(ticket_attrs(), fn attrs -> 
        %{attrs | assigned_to: [String.duplicate("a", 101)]}
      end)
    ])
  end

  # Private generators

  defp title_generator(opts) do
    min_length = Keyword.get(opts, :min_title_length, 1)
    max_length = Keyword.get(opts, :max_title_length, 100)

    string(:alphanumeric, min_length: min_length, max_length: max_length)
  end

  defp description_generator(opts) do
    min_length = Keyword.get(opts, :min_description_length, 1)
    max_length = Keyword.get(opts, :max_description_length, 500)

    string(:alphanumeric, min_length: min_length, max_length: max_length)
  end

  defp assigned_to_generator(opts) do
    max_length = Keyword.get(opts, :max_assigned_to_length, 50)

    email_generator =
      string(:alphanumeric, min_length: 5, max_length: 20) |> map(&"#{&1}@example.com")

    # Generate 0-3 assignees
    list(email_generator, min_length: 0, max_length: 3)
  end

  defp priority_generator do
    member_of([:low, :medium, :high, :urgent])
  end

  defp status_generator do
    member_of([:open, :in_progress, :resolved, :closed, :discarded])
  end

  defp UUID.generator() do
    gen all(bytes <- list(integer(0, 255), length: 16)) do
      <<uuid::binary-size(16)>> = :erlang.list_to_binary(bytes)
      <<a1::32, a2::16, a3::16, a4::16, a5::48>> = uuid

      :erlang.list_to_binary(
        :io_lib.format(
          "~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b",
          [a1, a2, a3, a4, a5]
        )
      )
    end
  end

  defp datetime_generator do
    gen all(timestamp <- integer(0, System.system_time(:second))) do
      DateTime.from_unix!(timestamp)
    end
  end
end
