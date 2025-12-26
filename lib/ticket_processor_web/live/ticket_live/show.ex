defmodule TicketProcessorWeb.TicketLive.Show do
  use TicketProcessorWeb, :live_view

  alias TicketProcessor.Tickets

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:ticket, Tickets.get_ticket!(id))}
  end

  defp page_title(:show), do: "Show Ticket"
  defp page_title(:edit), do: "Edit Ticket"

  @impl true
  def handle_event("confirm_discard", _params, socket) do
    {:ok, _ticket} = Tickets.discard_ticket(socket.assigns.ticket)
    {:noreply, push_navigate(socket, to: ~p"/tickets")}
  end
end
