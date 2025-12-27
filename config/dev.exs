import Config

# OpenTelemetry development configuration  
config :opentelemetry,
  processors: [{:otel_batch_processor, %{scheduled_delay_ms: 500}}]

# Configure Ash to allow non-atomic operations by default
config :ash,
  require_atomic_by_default?: false

# Configure TicketProcessor
config :ticket_processor, TicketProcessor.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ticket_processor_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, We can use it
# to bundle .js and .css sources.
config :ticket_processor, TicketProcessorWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to ip: {0, 0, 0, 1} to allow access from other machines.
  http: [ip: {0, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "jWx/zlES4575QgbKzx/zAHj5Z5lgOuRL5+M/rI0Z9Rq25npkSqlCzql6D+hpliHg",
  watchers: []
