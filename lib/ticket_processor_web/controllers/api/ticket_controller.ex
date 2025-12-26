defmodule TicketProcessorWeb.Api.TicketController do
  @moduledoc """
  REST controller for tickets API endpoints.
  """
  use TicketProcessorWeb, :controller

  alias TicketProcessor.Tickets

  action_fallback(TicketProcessorWeb.FallbackController)

  def index(conn, %{"status" => status}) do
    tickets = Tickets.list_tickets(%{status: status})
    render(conn, :index, tickets: tickets)
  end

  def index(conn, _params) do
    tickets = Tickets.list_tickets()
    render(conn, :index, tickets: tickets)
  end

  def show(conn, %{"id" => id}) do
    case Tickets.get_ticket(id) do
      {:ok, ticket} ->
        render(conn, :show, ticket: ticket)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Ticket not found"})
    end
  end

  def create(conn, %{"ticket" => ticket_params}) do
    case Tickets.create_ticket(ticket_params) do
      {:ok, ticket} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/tickets/#{ticket.id}")

        render(conn, :show, ticket: ticket)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id, "ticket" => ticket_params}) do
    case Tickets.get_ticket(id) do
      {:ok, ticket} ->
        case Tickets.update_ticket(ticket, ticket_params) do
          {:ok, updated_ticket} ->
            render(conn, :show, ticket: updated_ticket)

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: translate_errors(changeset)})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Ticket not found"})
    end
  end

  def assign(conn, %{"id" => id, "assignee" => assignee}) do
    case Tickets.get_ticket(id) do
      {:ok, ticket} ->
        case Tickets.add_assignee(ticket, assignee) do
          {:ok, updated_ticket} ->
            render(conn, :show, ticket: updated_ticket)

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: translate_errors(changeset)})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Ticket not found"})
    end
  end

  def remove_assignee(conn, %{"id" => id, "assignee" => assignee}) do
    case Tickets.get_ticket(id) do
      {:ok, ticket} ->
        case Tickets.remove_assignee(ticket, assignee) do
          {:ok, updated_ticket} ->
            render(conn, :show, ticket: updated_ticket)

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: translate_errors(changeset)})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Ticket not found"})
    end
  end

  def resolve(conn, %{"id" => id}) do
    case Tickets.get_ticket(id) do
      {:ok, ticket} ->
        case Tickets.resolve_ticket(ticket) do
          {:ok, resolved_ticket} ->
            render(conn, :show, ticket: resolved_ticket)

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: translate_errors(changeset)})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Ticket not found"})
    end
  end

  def close(conn, %{"id" => id}) do
    case Tickets.get_ticket(id) do
      {:ok, ticket} ->
        case Tickets.close_ticket(ticket) do
          {:ok, closed_ticket} ->
            render(conn, :show, ticket: closed_ticket)

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: translate_errors(changeset)})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Ticket not found"})
    end
  end

  def discard(conn, %{"id" => id}) do
    case Tickets.get_ticket(id) do
      {:ok, ticket} ->
        case Tickets.discard_ticket(ticket) do
          {:ok, discarded_ticket} ->
            render(conn, :show, ticket: discarded_ticket)

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: translate_errors(changeset)})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Ticket not found"})
    end
  end

  def delete(conn, %{"id" => id}) do
    case Tickets.get_ticket(id) do
      {:ok, ticket} ->
        case Tickets.discard_ticket(ticket) do
          {:ok, _discarded_ticket} ->
            conn
            |> put_status(:ok)
            |> json(%{message: "Ticket discarded successfully"})

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: translate_errors(changeset)})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Ticket not found"})
    end
  end

  # Private helpers

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      message
    end)
  end
end
