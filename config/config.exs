import Config

# Configures Elixir's Logger
config :logger, :console, format: "[$level] $message $metadata\n", level: :info

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
