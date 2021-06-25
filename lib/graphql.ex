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
      @defaults %{options: @http_options, headers: @http_headers, max_attempts: @max_attempts}

      @spec call(
              query :: String.t(),
              variables :: map(),
              options :: Keyword.t()
            ) :: Client.bridge_response()
      def call(query, variables, options \\ []) do
        %{options: http_options, headers: http_headers, max_attempts: max_attempts} =
          Enum.into(options, @defaults)

        @endpoint
        |> Client.call(
          query,
          encode_variables(variables),
          http_options,
          http_headers,
          max_attempts
        )
        |> format_response()
      end

      # define helpers at compile-time, to avoid dialyzer errors about pattern matching constants
      if Keyword.get(unquote(opts), :encode_variables, false) do
        defp encode_variables(variables), do: Jason.encode!(variables)
      else
        defp encode_variables(variables), do: variables
      end

      if Keyword.get(unquote(opts), :format_response, false) do
        defp format_response({ret, response}), do: {ret, Client.format_response(response)}
      else
        defp format_response({ret, response}), do: {ret, response}
      end
    end
  end
end
