# BridgeEx

A library to build bridges to other services (actually only graphql ones are supported).

## Usage

### A GraphQL bridge

Define a behaviour with the queries/mutations you're going to need for the bridge:

```elixir
defmodule MyApp.SomeService do
  @moduledoc """
  Bridge definition for SomeService
  """

  @callback my_cool_query(any()) :: {:ok, map()} | {:error, any()}
end
```

Implement the behaviour:

```elixir
defmodule MyApp.SomeServiceBridge do
  @moduledoc """
  Bridge implementation for SomeService behaviour.
  """

  @behaviour MyApp.SomeService

  use BridgeEx.Graphql, [
    # mandatory settings
    endpoint: "http://some_service.example.com",

    # optional settings (with defaults)
    http_headers: %{
      "User-Agent" => "microservice-myapp/myapp-version",
      "Content-type" => "application/json",
      "X-Client-Id" => "myapp",
      "X-Client-Secret" => "myapp_secret"
    },
    http_options: [timeout: 1_000, recv_timeout: 16_000],
    max_attempts: 1,
    encode_variables: false,
    format_response: true # formats keys from CamelCase to snake_case
  ]

  def my_cool_query(%{} = variables) do
    call("a graphql query or mutation", variables)

    # or, if you need more granularity (ex: different endpoint or options):

    # BridgeEx.Graphql.Client.call(
    #   "https://another-url.com/graphql",
    #   "graphql query or mutation",
    #   variables,
    #   encode_variables: false,
    #   [timeout: 1_000, recv_timeout: 16_000],
    #   %{
    #     "Some-Header" => "some-value",
    #   },
    #   1
    # )

  end
end
```

You can now use your bridge module:

```elixir
MyApp.SomeServiceBridge.my_cool_query(%{var: 1})
```

As a good practice, if you want to mock your bridge for testing, you _should_ implement another module:

```elixir
defmodule MyApp.SomeServiceBridgeMock do
  @behaviour MyApp.SomeService

  alias BridgeEx.Graphql.Utils


  def my_cool_query(%{} = variables) do
    File.read!("some_mock_file.json")
    |> Json.decode!(keys: :atoms)
    |> Utils.parse_response() # required to parse data
    # |> BridgeEx.Graphql.Client.format_response() # optional, if you want to format response
  end
end
```

You can now set the right module in your `config/*` directory:

```elixir
config :my_app, :some_service_bridge, MyApp.SomeServiceBridge

# or

config :my_app, :some_service_bridge, MyApp.SomeServiceBridgeMock
```

And use it in your app from configuration:

```elixir
@some_service Application.compile_env!(:my_app, :some_service_bridge)

# ...

@some_service.my_cool_query(%{var: 2})
```

See [example](example) directory for an implementation, it also works in `dev` and `test` environments.

### Authenticating calls via Auth0

`bridge_ex` supports authentication of machine-to-machine calls via Auth0, through the [prima_auth0_ex](https://github.com/primait/auth0_ex) library.

To use this feature, simply configure your bridge with the audience of the target service:

```elixir
  use BridgeEx.Graphql, [endpoint: "...", auth0: [enabled: true, audience: "target_audience"]]
```

For this feature to work, your `config.exs` must be updated with the configuration for the `prima_auth0_ex` library.
You can refer to [the library's README](https://github.com/primait/auth0_ex/blob/master/README.md#configuration) for more information on the supported configuration.

## Development

`mix deps.get && mix test`

## Installation

The package can be installed by adding `bridge_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bridge_ex, "~> 0.4.0"}
  ]
end
```

## Copyright and License

Copyright (c) 2020 Prima.it

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the [LICENSE.md](./LICENSE.md) file for more details.
