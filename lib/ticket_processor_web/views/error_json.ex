defmodule TicketProcessorWeb.ErrorJSON do
  def render("error.json", %{changeset: changeset}) do
    %{
      errors:
        Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} ->
          message
        end)
    }
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end
end
