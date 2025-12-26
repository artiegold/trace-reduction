defmodule TicketProcessorWeb.TicketJSON do
  @moduledoc """
  JSON view for rendering tickets.
  """

  alias TicketProcessor.Tickets.Ticket

  def render("index.json", %{tickets: tickets}) do
    %{data: render_many(tickets), meta: %{count: length(tickets)}}
  end

  def render("show.json", %{ticket: ticket}) do
    %{data: render_one(ticket)}
  end

  def render_many(tickets) do
    for ticket <- tickets do
      render_one(ticket)
    end
  end

  def render_one(%Ticket{} = ticket) do
    %{
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      status: ticket.status,
      priority: ticket.priority,
      assigned_to: ticket.assigned_to,
      created_at: ticket.created_at,
      updated_at: ticket.updated_at
    }
  end
end
