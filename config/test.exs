import Config

config :prima_auth0_ex,
  token_cache: NoopCache

config :prima_auth0_ex, :clients,
  default_client: [
    # auth0_base_url: "configure in tests",
    client_id: "",
    client_secret: "",
    cache_namespace: "default_client"
  ]

config :prima_auth0_ex, :clients,
  test_client: [
    # auth0_base_url: "configure in tests",
    client_id: "",
    client_secret: "",
    cache_namespace: "test_client"
  ]
