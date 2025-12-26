defmodule TicketProcessorWeb.FallbackController do
  use TicketProcessorWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: TicketProcessorWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: TicketProcessorWeb.ErrorJSON)
    |> render(:error, message: "Not found")
  end

  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: TicketProcessorWeb.ErrorJSON)
    |> render(:error, message: message)
  end
end
