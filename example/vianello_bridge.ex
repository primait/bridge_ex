defmodule VianelloBridge do
  @moduledoc """
  Bridge implementation for Vianello behaviour.
  """
  @behaviour Vianello

  use BridgeEx, [
    http_options: [timeout: 1_000, recv_timeout: 16_000],
    http_headers: %{
      "User-Agent" => "prima-microservice-myapp/myapp-version",
      "Content-type" => "application/json",
      "X-Client-Id" => "myapp",
      "X-Client-Secret" => "myapp_secret"
    },
    max_attempts: 1,
    encode_variables: false
  ]

  # actually implement the callbacks
  def my_cool_query(_args) do
    call("url", "query", %{var: 1})
    false
  end
end
