# BridgeEx

A library to build bridges to other services (actually only graphql ones are supported).

## Usage

### Graphql

Bridges to Graphql services are defined by `use`ing the `BridgeEx.Graphql` macro as follows:

```elixir
defmodule MyApp.SomeServiceBridge do
  use BridgeEx.Graphql, endpoint: "http://some_service.example.com"

  def my_query(%{} = variables) do
    call("a graphql query or mutation", variables)
  end
end
```

Besides `endpoint`, the following parameters can be optionally set when `use`ing `BridgeEx.Graphql`:

- `auth0`
- `encode_variables`
- `format_response`
- `http_headers`
- `http_options`
- `log_options`
- `max_attempts`

Refer to [the documentation](https://hexdocs.pm/bridge_ex/BridgeEx.Graphql.html) for more details.

If you need more control on your requests you can use [`BridgeEx.Graphql.Client.call`](https://hexdocs.pm/bridge_ex/BridgeEx.Graphql.Client.html#call/7) directly.

### Global configuration

The following configuration parameters can be set globally for all bridges in the app, by setting them inside your `config.exs`:

- `config :bridge_ex, auth0_enabled: true` to allow bridges to enable integration with Auth0
- `config :bridge_ex, log_options: [log_query_on_error: true, log_response_on_error: false]` to customize logging in your bridges

### Authenticating calls via Auth0

`bridge_ex` supports authentication of machine-to-machine calls via Auth0, through the [prima_auth0_ex](https://github.com/primait/auth0_ex) library.

To use this feature do the following:

- update your `config.exs`:

  - enable auth0 support for the application in the environment: `config :bridge_ex, auth0_enabled: true`
  - add the necessary config to create API consumers with `prima_auth0_ex`, see [the documentation](https://github.com/primait/auth0_ex#api-consumer)

- add `:prima_auth0_ex` as a dependency in your mix project

Then configure your bridge with the audience of the target service:

```elixir
use BridgeEx.Graphql,
  endpoint: "...",
  auth0: [enabled: true, audience: "target_audience"]
```

Note that Auth0 integration **must be explicitly enabled for each bridge** where you want it by setting `auth0: [enable: true]`, as per the example above.

## Testing your bridge

As a good practice, if you want to mock your bridge for testing, you _should_ define a behaviour:

```elixir
defmodule MyApp.SomeService do
  @callback my_cool_query(any()) :: {:ok, map()} | {:error, any()}
end
```

Then implement it for your bridge:

```elixir
defmodule MyApp.SomeServiceBridge do
  @behaviour MyApp.SomeService

  use BridgeEx.Graphql, endpoint: "..."
  ...
end
```

And finally implement it again for the mock:

```elixir
defmodule MyApp.SomeServiceBridgeMock do
  @behaviour MyApp.SomeService

  alias BridgeEx.Graphql.Utils

  def my_cool_query(%{} = variables) do
    File.read!("some_mock_file.json")
    |> Json.decode!(keys: :atoms)
    # required to parse data
    |> Utils.parse_response()
    # optional, if you want to format response
    # |> BridgeEx.Graphql.Client.format_response()\
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

## Development

`mix deps.get && mix test`

## Installation

The package can be installed by adding `bridge_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bridge_ex, "~> 1.0.0"}
    # only if you want auth0 too
    # {:prima_auth0_ex, "~> 0.3.0"}
  ]
end
```

## Copyright and License

Copyright (c) 2020 Prima.it

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the [LICENSE.md](./LICENSE.md) file for more details.
