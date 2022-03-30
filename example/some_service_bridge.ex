defmodule BridgeEx.Example.SomeServiceBridge do
  @moduledoc """
  Bridge implementation for SomeService behaviour.
  """

  @behaviour BridgeEx.Example.SomeService

  use BridgeEx.Graphql, [
    # mandatory settings (values of `http_headers` might differ for your use case)
    endpoint: "http://some_service.example.com",
    http_headers: %{
      "User-Agent" => "microservice-myapp/myapp-version",
      "Content-type" => "application/json"
    },

    # optional settings (with defaults)
    http_options: [timeout: 1_000, recv_timeout: 16_000],
    encode_variables: false,
    format_response: true
  ]

  def my_cool_query(%{id: "12345"} = variables) do
    "#{__DIR__}/some_service/my_cool_query.graphql"
    |> File.read!()
    |> call(variables, retry_options: [max_retries: 1])
  end
end
