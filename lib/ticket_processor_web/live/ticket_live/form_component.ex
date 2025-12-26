defmodule TicketProcessorWeb.TicketLive.FormComponent do
  use TicketProcessorWeb, :live_component

  alias TicketProcessor.Tickets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="ticket-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input 
          field={@form[:assigned_to]} 
          type="text" 
          label="Assigned To (comma-separated emails or usernames)"
          value={Enum.join(@form[:assigned_to].value || [], ", ")}
        />
        <.input field={@form[:priority]} type="select" label="Priority" options={priority_options()} />
        <.button type="submit" phx-disable-with="Saving...">Save Ticket</.button>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{ticket: ticket} = assigns, socket) do
    changeset = Tickets.change_ticket(ticket)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"ticket" => ticket_params}, socket) do
    # Parse comma-separated assignees into a list for validation
    processed_params = parse_assignees(ticket_params)

    changeset =
      socket.assigns.ticket
      |> Tickets.change_ticket(processed_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"ticket" => ticket_params}, socket) do
    save_ticket(socket, socket.assigns.action, ticket_params)
  end

  defp save_ticket(socket, :edit, ticket_params) do
    # Parse comma-separated assignees into a list
    processed_params = parse_assignees(ticket_params)

    case Tickets.update_ticket(socket.assigns.ticket, processed_params) do
      {:ok, ticket} ->
        notify_parent({:saved, ticket})

        {:noreply,
         socket
         |> put_flash(:info, "Ticket updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_ticket(socket, :new, ticket_params) do
    # Parse comma-separated assignees into a list
    processed_params = parse_assignees(ticket_params)

    case Tickets.create_ticket(processed_params) do
      {:ok, ticket} ->
        notify_parent({:saved, ticket})

        {:noreply,
         socket
         |> put_flash(:info, "Ticket created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp parse_assignees(params) do
    case Map.get(params, "assigned_to") do
      nil ->
        Map.put(params, :assigned_to, [])

      "" ->
        Map.put(params, :assigned_to, [])

      assignees_str ->
        assignee_list =
          assignees_str
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.uniq()

        Map.put(params, :assigned_to, assignee_list)
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp priority_options do
    [
      {"Low", :low},
      {"Medium", :medium},
      {"High", :high},
      {"Urgent", :urgent}
    ]
  end
end
