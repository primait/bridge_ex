defmodule BridgeEx.Graphql do
  @moduledoc """
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
    * `max_attempts`: number of times the request will be retried upon failure. Defaults to `1`. ⚠️ Deprecated: use retry_options instead.
    * `retry_options`: override configuration regarding retries, namely
      * `delay`: meaning depends on `timing`
        * `:constant`: retry ever `delay` ms
        * `:exponential`: start retrying with `delay` ms
      * `max_retries`. Defaults to `0`
      * `policy`: a function that takes an error as input and returns `true`/`false` to indicate whether to retry the error or not. Defaults to "always retry" (`fn _ -> true end`).
      * `timing`: either `:exponential` or `:constant`, indicates how frequently retries are made (e.g. every 1s, in an exponential manner and so on). Defaults to `:exponential`

  ## Examples

  ```elixir
  defmodule MyBridge do
    use BridgeEx.Graphql, endpoint: "http://my-api.com/graphql"
  end

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
      @log_options Keyword.get(unquote(opts), :log_options)

      if Keyword.has_key?(unquote(opts), :max_attempts) do
        IO.warn(
          "max_attemps is deprecated, please use retry_options[:max_retries] instead",
          Macro.Env.stacktrace(__ENV__)
        )
      end

      @doc """
      Run a graphql query or mutation over the configured bridge.

      ## Options

        * `options`: extra HTTP options to be passed to Telepoison.
        * `headers`: extra HTTP headers.
        * `max_attempts`: override the configured `max_attempts` parameter. ⚠️ Deprecated: use retry_options instead.
        * `retry_options`: override the default retry options.

      ## Return values

        * `{:ok, graphql_response}` on success
        * `{:error, graphql_error}` on graphql error (i.e. 200 status code but `errors` array is not `nil`)
        * `{:error, {:bad_response, status_code}}` on non 200 status code
        * `{:error, {:http_error, reason}}` on http error e.g. `:econnrefused`

      ## Examples

        iex> MyBridge.call("some_query", %{var_key: "var_value"})
        iex> MyBridge.call("some_query", %{var_key: "var_value"}, retry_options: [max_retries: 3])
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

        user_retry_options = Keyword.get(options, :retry_options, [])

        retry_options =
          Keyword.merge(
            [
              delay: 100,
              max_retries: max_attempts - 1,
              policy: fn _ -> true end,
              timing: :exponential
            ],
            user_retry_options
          )

        with {:ok, http_headers} <- with_authorization_headers(http_headers) do
          @endpoint
          |> Client.call(
            query,
            encode_variables(variables),
            http_options,
            http_headers,
            retry_options,
            log_options()
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
        raise """
        Auth0 is enabled but audience is not set for bridge in module #{__MODULE__}.
        Please either set an audience for this bridge or disable auth0 locally:

          # Either this
          use BridgeEx.Graphql, auth0: [audience: "my-audience"]

          # or this
          use BridgeEx.Graphql, auth0: [enabled: false]
        """
      end

      if @audience && @auth0_enabled do
        unless Code.ensure_loaded?(PrimaAuth0Ex) do
          raise """
          Auth0 is enabled but :prima_auth0_ex is not loaded. Did you add it to your dependencies?
          """
        end

        defp with_authorization_headers(headers) do
          with {:ok, authorization_headers} <-
                 Auth0AuthorizationProvider.authorization_headers(@audience) do
            {:ok, Enum.into(authorization_headers, headers)}
          end
        end
      else
        defp with_authorization_headers(headers), do: {:ok, headers}
      end

      # Local log options always have precedence over global log options
      if @log_options do
        defp log_options, do: @log_options
      else
        defp log_options do
          Application.get_env(:bridge_ex, :log_options,
            log_query_on_error: false,
            log_response_on_error: false
          )
        end
      end
    end
  end
end
