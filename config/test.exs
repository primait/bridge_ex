import Config

config :prima_auth0_ex, :redis, enabled: false

config :prima_auth0_ex, :clients,
  default_client: [
    # auth0_base_url: "configure in tests",
    client_id: "",
    client_secret: "",
    cache_namespace: "test"
  ]
