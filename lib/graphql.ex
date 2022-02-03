defmodule BridgeEx.Graphql do
  @moduledoc """
  Main module to be used to implement graphql bridges.
  """

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro __using__(opts) when is_list(opts) do
    quote do
      alias BridgeEx.Auth0AuthorizationProvider
      alias BridgeEx.Graphql.Client

      # mandatory opts
      @endpoint Keyword.fetch!(unquote(opts), :endpoint)

      # optional opts with defaults
      @audience get_in(unquote(opts), [:auth0, :audience])
      @auth0_enabled get_in(unquote(opts), [:auth0, :enabled])
      @http_options Keyword.get(unquote(opts), :http_options, timeout: 1_000, recv_timeout: 16_000)
      @http_headers Keyword.get(unquote(opts), :http_headers, %{
                      "Content-type" => "application/json"
                    })
      @max_attempts Keyword.get(unquote(opts), :max_attempts, 1)
      @log_options Keyword.get(unquote(opts), :log_options,
                     log_query_on_error: false,
                     log_response_on_error: false
                   )

      @spec call(
              query :: String.t(),
              variables :: map(),
              options :: Keyword.t()
            ) :: Client.bridge_response()
      def call(query, variables, options \\ []) do
        http_options = Keyword.merge(@http_options, Keyword.get(options, :options, []))
        http_headers = Map.merge(@http_headers, Keyword.get(options, :headers, %{}))
        max_attempts = Keyword.get(options, :max_attempts, @max_attempts)
        log_options = Keyword.merge(@log_options, Keyword.get(options, :log_options, []))

        with {:ok, http_headers} <- with_authorization_headers(http_headers) do
          @endpoint
          |> Client.call(
            query,
            encode_variables(variables),
            http_options,
            http_headers,
            max_attempts,
            log_options
          )
          |> format_response()
        end
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

      if @audience && @auth0_enabled do
        defp with_authorization_headers(headers) do
          with {:ok, authorization_headers} <-
                 Auth0AuthorizationProvider.authorization_headers(@audience) do
            {:ok, Enum.into(authorization_headers, headers)}
          end
        end
      else
        defp with_authorization_headers(headers), do: {:ok, headers}
      end
    end
  end
end
