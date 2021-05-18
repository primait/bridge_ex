# BridgeEx

A library to build graphql bridges to other services.

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
    # mandatory settings (values of `http_headers` might differ for your use case)
    endpoint: "http://some_service.example.com",
    http_headers: %{
      "User-Agent" => "microservice-myapp/myapp-version",
      "Content-type" => "application/json",
      "X-Client-Id" => "myapp",
      "X-Client-Secret" => "myapp_secret"
    },
    # optional settings (with defaults)
    http_options: [timeout: 1_000, recv_timeout: 16_000],
    max_attempts: 1,
    encode_variables: false
  ]

  def my_cool_query(%{} = variables) do
    call("a graphql query or mutation", variables)
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

  def my_cool_query(%{} = variables) do
    File.read!("some_mock_file.json")
    |> Json.decode!(keys: :atoms)
    |> BridgeEx.Graphql.Client.format_response()
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

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bridge_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bridge_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bridge_ex](https://hexdocs.pm/bridge_ex).
