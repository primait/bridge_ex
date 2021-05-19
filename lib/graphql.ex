defmodule BridgeEx.Graphql do
  @moduledoc """
  Main module to be used to implement graphql bridges.
  """

  defmacro __using__(opts) when is_list(opts) do
    quote do
      alias BridgeEx.Graphql.Client
      # mandatory opts
      @endpoint Keyword.fetch!(unquote(opts), :endpoint)

      # optional opts with defaults
      @http_options Keyword.get(unquote(opts), :http_options, timeout: 1_000, recv_timeout: 16_000)
      @http_headers Keyword.get(unquote(opts), :http_headers, %{
                      "Content-type" => "application/json"
                    })
      @max_attempts Keyword.get(unquote(opts), :max_attemps, 1)
      @encode_variables Keyword.get(unquote(opts), :encode_variables, false)

      @defaults %{options: @http_options, headers: @http_headers, max_attempts: @max_attempts}

      @spec call(
              query :: String.t(),
              variables :: map(),
              options :: Keyword.t()
            ) :: Client.bridge_response()
      def call(query, variables, options \\ []) do
        %{options: http_options, headers: http_headers, max_attempts: max_attempts} =
          Enum.into(options, @defaults)

        request_variables =
          case @encode_variables do
            false -> variables
            true -> Jason.encode!(variables)
          end

        Client.call(@endpoint, query, request_variables, http_options, http_headers, max_attempts)
      end
    end
  end
end
