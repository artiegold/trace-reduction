defmodule TicketProcessorWeb.TicketLive.Index do
  use TicketProcessorWeb, :live_view

  alias TicketProcessor.Tickets
  alias TicketProcessor.Tickets.Ticket

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :tickets, Tickets.list_tickets())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Ticket")
    |> assign(:ticket, Tickets.get_ticket!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Ticket")
    |> assign(:ticket, %Ticket{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Tickets")
    |> assign(:ticket, nil)
  end

  @impl true
  def handle_info({TicketProcessorWeb.TicketLive.FormComponent, {:saved, ticket}}, socket) do
    {:noreply, stream_insert(socket, :tickets, ticket)}
  end

  @impl true
  def handle_event("discard", %{"id" => id}, socket) do
    ticket = Tickets.get_ticket!(id)

    # Discard instead of destroy
    {:ok, _} = Tickets.discard_ticket(ticket)

    {:noreply, stream_delete(socket, :tickets, ticket)}
  end
end
