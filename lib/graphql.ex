defmodule BridgeEx.Graphql do
  @moduledoc """
  Main module to be used to implement graphql bridges.

  You need to provide an `endpoint` on `use`, e.g.

  ```
  use BridgeEx.Graphql, endpoint: "https://your.auth0.endpoint"
  ```
  """

  @doc """
  Create a Graphql bridge in the given module.

  Once created, a graphql request can be made via `MyBridge.call("my-query", %{"variable": "var"})`

  ## Options

    * `endpoint` (required): URL of the remote Graphql endpoint.
    * `auth0`: enable and configure Auth0 for authentication of requests. Takes the form of `[enabled: false, audience: "target-audience"]`.
    * `encode_variables`: if true, encode the Graphql variables to JSON. Defaults to `false`.
    * `format_response`: transforms camelCase keys in response to snake_case. Defaults to `false`.
    * `http_headers`: HTTP headers for the request. Defaults to `%{"Content-type": "application/json"}`
    * `http_options`: HTTP options to be passed to Telepoison. Defaults to `[timeout: 1_000, recv_timeout: 16_000]`.
    * `log_options`: override global configuration for logging errors. Takes the form of `[log_query_on_error: false, log_response_on_error: false]`
    * `max_attempts`: number of times the request will be retried upon failure. Defaults to `1`.

  ## Examples

  ```elixir
  defmodule MyBridge do
    use BridgeEx.Graphql, endpoint: "http://my-api.com/graphql"
  end
  ```

  ```elixir
  defmodule MyBridge do
    use BridgeEx.Graphql,
      endpoint: "http://my-api.com/graphql",
      auth0: [enabled: true, audience: "target-audience"]
  end
  ```
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro __using__(opts) when is_list(opts) do
    quote do
      require Logger

      alias BridgeEx.Auth0AuthorizationProvider
      alias BridgeEx.Graphql.Client

      # global config
      @global_log_options Application.compile_env(:bridge_ex, :log_options,
                            log_query_on_error: false,
                            log_response_on_error: false
                          )

      # local config
      # mandatory opts
      @endpoint Keyword.fetch!(unquote(opts), :endpoint)

      # optional opts with defaults
      @auth0_enabled get_in(unquote(opts), [:auth0, :enabled]) || false
      @audience get_in(unquote(opts), [:auth0, :audience])
      @http_options Keyword.get(unquote(opts), :http_options, timeout: 1_000, recv_timeout: 16_000)
      @http_headers Keyword.get(unquote(opts), :http_headers, %{
                      "Content-type" => "application/json"
                    })
      @max_attempts Keyword.get(unquote(opts), :max_attempts, 1)
      @log_options Keyword.get(unquote(opts), :log_options, @global_log_options)

      @doc """
      Run a graphql query or mutation over the configured bridge.

      ## Options

        * `options`: extra HTTP options to be passed to Telepoison.
        * `headers`: extra HTTP headers.
        * `max_attempts`: override the configured `max_attempts` parameter.

      ## Examples

        iex> MyBridge.call("some_query", %{var_key: "var_value"})
        iex> MyBridge.call("some_query", %{var_key: "var_value"}, max_attempts: 3)
      """
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
          file: __ENV__.file,
          line: __ENV__.line,
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
