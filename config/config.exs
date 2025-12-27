# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ticket_processor,
  ecto_repos: [TicketProcessor.Repo],
  generators: [timestamp_type: :utc_datetime, ash_domain: false]

# Configure the endpoint
config :ticket_processor, TicketProcessorWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TicketProcessorWeb.ErrorHTML, json: TicketProcessorWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TicketProcessor.PubSub,
  live_view: [signing_salt: "r7z3KvUA"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ticket_processor, TicketProcessor.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  ticket_processor: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  ticket_processor: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Ash domains
config :ticket_processor, ash_domains: [TicketProcessor.Tickets]

# Ash configuration
config :ash, :use_all_api_sockets?, true

# OpenTelemetry configuration
config :opentelemetry,
  span_processor: :batch,
  exporters: [
    otlp: [
      protocol: :grpc,
      endpoints: [{:http, ~c"localhost", 4317}]
    ]
  ]

config :opentelemetry_exporter,
  otlp_protocol: :grpc

config :opentelemetry_process_propagator,
  text_map_propagator: :trace_context

config :opentelemetry_phoenix,
  # Enable Phoenix endpoint instrumentation
  router: TicketProcessorWeb.Router

# Configure Ecto telemetry for OpenTelemetry
config :opentelemetry_ecto,
  comment: :parent,
  command_prefix: ["TicketProcessor", "Repo"]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
