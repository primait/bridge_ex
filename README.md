# GraphqlBridge

A library to build graphql bridges to other services.

## Development

- build image:

`docker build -t graphql_bridge`

- run shell inside it:

`docker run -it graphql_bridge`

Or, just run the provided shell script:

`./docker-start.sh`

- Once inside the container, download dependencies and run tests:

`mix deps.get && mix test`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `graphql_bridge` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:graphql_bridge, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/graphql_bridge](https://hexdocs.pm/graphql_bridge).
