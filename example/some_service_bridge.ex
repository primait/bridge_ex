defmodule BridgeEx.Example.SomeServiceBridge do
  @moduledoc """
  Bridge implementation for SomeService behaviour.
  """

  @behaviour BridgeEx.Example.SomeService

  use BridgeEx.Graphql, [
    endpoint: "http://some_service.example.com",
    http_options: [timeout: 1_000, recv_timeout: 16_000],
    http_headers: %{
      "User-Agent" => "microservice-myapp/myapp-version",
      "Content-type" => "application/json",
      "X-Client-Id" => "myapp",
      "X-Client-Secret" => "myapp_secret"
    },
    max_attempts: 1,
    encode_variables: false
  ]

  # actually implement the callbacks
  def my_cool_query(_args) do
    call("query", %{var: 1})
    false
  end
end
