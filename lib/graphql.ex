defmodule BridgeEx.Graphql do
  @moduledoc """
  Main module to be used to implement graphql bridges.
  """

  defmacro __using__(opts) when is_list(opts) do
    quote do
      alias BridgeEx.Graphql.Client

      # mandatory opts
      @endpoint Keyword.fetch!(unquote(opts), :endpoint)
      @http_headers Keyword.fetch!(unquote(opts), :http_headers)

      # optional opts with defaults
      @http_options Keyword.get(unquote(opts), :http_options, timeout: 1_000, recv_timeout: 16_000)
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

        call_func =
          case @encode_variables do
            false -> :call_no_variables_encoding
            true -> :call
          end

        apply(Client, call_func, [
          @endpoint,
          query,
          variables,
          http_options,
          http_headers,
          max_attempts
        ])
      end
    end
  end
end
