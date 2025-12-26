defmodule TicketProcessorWeb.Router do
  use TicketProcessorWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {TicketProcessorWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", TicketProcessorWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    live("/tickets", TicketLive.Index, :index)
    live("/tickets/new", TicketLive.Index, :new)
    live("/tickets/:id", TicketLive.Show, :show)
    live("/tickets/:id/edit", TicketLive.Show, :edit)
    live("/tickets/:id/discard", TicketLive.Show, :discard)
  end

  # API routes
  scope "/api", TicketProcessorWeb do
    pipe_through(:api)

    resources("/tickets", Api.TicketJSONController, except: [:new, :edit])
    put("/tickets/:id/assign", Api.TicketJSONController, :assign)
    put("/tickets/:id/remove_assignee", Api.TicketJSONController, :remove_assignee)
    put("/tickets/:id/resolve", Api.TicketJSONController, :resolve)
    put("/tickets/:id/close", Api.TicketJSONController, :close)
    put("/tickets/:id/discard", Api.TicketJSONController, :discard)
  end

  # API Documentation
  scope "/api/docs" do
    pipe_through(:browser)
    get("/", TicketProcessorWeb.ApiDocs, :index)
    get("/openapi.yaml", TicketProcessorWeb.ApiDocs, :openapi_spec)
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ticket_processor, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: TicketProcessorWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
