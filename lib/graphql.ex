defmodule BridgeEx.Graphql do
  @moduledoc """
  Main module to be used to implement graphql bridges.

  You need to provide an `endpoint` on `use`, e.g.

  ```
  use BridgeEx.Graphql,
    endpoint: "https://your.auth0.endpoint"
  ```
  """

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro __using__(opts) when is_list(opts) do
    quote do
      alias BridgeEx.Auth0AuthorizationProvider
      alias BridgeEx.Graphql.Client

      # global config
      @global_auth0_enabled Application.compile_env(:bridge_ex, :auth0_enabled, false)
      @global_log_options Application.compile_env(:bridge_ex, :log_options,
                            log_query_on_error: false,
                            log_response_on_error: false
                          )

      # local config
      # mandatory opts
      @endpoint Keyword.fetch!(unquote(opts), :endpoint)

      # optional opts with defaults
      @audience get_in(unquote(opts), [:auth0, :audience])
      @auth0_enabled if (result = get_in(unquote(opts), [:auth0, :enabled])) == nil,
                       do: @global_auth0_enabled,
                       else: result
      @http_options Keyword.get(unquote(opts), :http_options, timeout: 1_000, recv_timeout: 16_000)
      @http_headers Keyword.get(unquote(opts), :http_headers, %{
                      "Content-type" => "application/json"
                    })
      @max_attempts Keyword.get(unquote(opts), :max_attempts, 1)
      @log_options Keyword.get(unquote(opts), :log_options, @global_log_options)

      @spec call(
              query :: String.t(),
              variables :: map(),
              options :: Keyword.t()
            ) :: Client.bridge_response()
      def call(query, variables, options \\ []) do
        http_options = Keyword.merge(@http_options, Keyword.get(options, :options, []))
        http_headers = Map.merge(@http_headers, Keyword.get(options, :headers, %{}))
        max_attempts = Keyword.get(options, :max_attempts, @max_attempts)

        with {:ok, http_headers} <- with_authorization_headers(http_headers) do
          @endpoint
          |> Client.call(
            query,
            encode_variables(variables),
            http_options,
            http_headers,
            max_attempts,
            @log_options
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

      if @audience == nil && @auth0_enabled do
        raise CompileError,
          description: """
          Auth0 is enabled but audience is not set for bridge in module #{__MODULE__}.
          Please either set an audience for this bridge or disable auth0 locally:

            # Either this
            use BridgeEx.Graphql, auth0: [audience: "my-audience"]

            # or this
            use BridgeEx.Graphql, auth0: [enabled: false]
          """
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
