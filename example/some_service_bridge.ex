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
      "Content-type" => "application/json",
      "X-Client-Id" => "myapp",
      "X-Client-Secret" => "myapp_secret"
    },

    # optional settings (with defaults)
    http_options: [timeout: 1_000, recv_timeout: 16_000],
    max_attempts: 1,
    encode_variables: false
  ]

  def my_cool_query(%{} = variables) do
    call("query", variables)
    false
  end
end
