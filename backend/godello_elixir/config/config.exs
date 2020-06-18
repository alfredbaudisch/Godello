# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :godello,
  ecto_repos: [Godello.Repo]

# Configures the endpoint
config :godello, GodelloWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Qesdy3wjb63zKfYaNesskJTsKyVrwPokLmTN33iCDLWCsoL1eI9H8uvqN9LGeuAv",
  render_errors: [view: GodelloWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Godello.PubSub,
  live_view: [signing_salt: "kRv9nFTU"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
