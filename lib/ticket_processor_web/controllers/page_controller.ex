defmodule TicketProcessorWeb.PageController do
  use TicketProcessorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
