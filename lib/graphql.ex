defmodule BridgeEx.Graphql do
  @moduledoc """
  Create a Graphql bridge in the given module.

  Once created, a graphql request can be made via `MyBridge.call("my-query", %{"variable": "var"})`

  ## Options

    * `endpoint`: URL of the remote Graphql endpoint.
    * `auth0`: enable and configure Auth0 for authentication of requests. Takes the form of `[enabled: false, audience: "target-audience"]`.
    * `encode_variables`: if true, encode the Graphql variables to JSON. Defaults to `false`.
    * `format_response`: transforms camelCase keys in response to snake_case. Defaults to `false`.
    * `format_variables`: transforms snake_case variable names to camelCase. Defaults to `false`.
    * `http_headers`: HTTP headers for the request. Defaults to `%{"Content-type": "application/json"}`.
    * `http_options`: HTTP options to be passed to Telepoison. Defaults to `[timeout: 1_000, recv_timeout: 16_000]`.
    * `log_options`: override global configuration for logging errors. Takes the form of `[log_query_on_error: false, log_response_on_error: false]`.
    * `max_attempts`: number of times the request will be retried upon failure. Defaults to `1`. ⚠️ Deprecated: use `retry_options` instead.
    * `decode_keys`: determines how JSON keys in GraphQL responses are decoded. Can be set to `:atoms`, `:strings` or `:existing_atoms`. Currently, the default mode is `:atoms` but will be changed to `:strings` in a future version of this library. You are highly encouraged to set this option to `:strings` to avoid [memory leaks and security concerns](https://hexdocs.pm/jason/Jason.html#decode/2-decoding-keys-to-atoms).
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

  # If you would like to configure this options to use runtime values,
  # you can do so through your config e.g.
  config :bridge_ex, MyBridge,
    endpoint: "http://my-api.com/graphql"
  ```
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro __using__(opts \\ []) when is_list(opts) do
    if Keyword.has_key?(opts, :max_attempts) do
      IO.warn(
        "max_attemps is deprecated, please use retry_options[:max_retries] instead",
        Macro.Env.stacktrace(__ENV__)
      )
    end

    unless Keyword.has_key?(opts, :decode_keys) do
      IO.warn(
        "missing decode_keys option for this GraphQL bridge. Currently fallbacks to :atoms which may lead to memory leaks and raise security concerns. If you want to keep the current behavior and hide this warning, just add `decode_keys: :atoms` to the options of this bridge. You should however consider migrating to `decode_keys: :strings`.",
        Macro.Env.stacktrace(__ENV__)
      )
    end

    quote do
      alias BridgeEx.Auth0AuthorizationProvider
      alias BridgeEx.Graphql.Client
      alias BridgeEx.Graphql.Formatter.SnakeCase
      alias BridgeEx.Graphql.Formatter.Adapter
      alias BridgeEx.Graphql.Utils

      @compile_opts unquote(opts)

      defp get_opt(key, default \\ nil)

      defp get_opt(key, default) when is_atom(key) do
        if Keyword.has_key?(@compile_opts, key) do
          Keyword.get(@compile_opts, key, default)
        else
          :bridge_ex
          |> Application.get_env(__MODULE__, [])
          |> Keyword.get(key, default)
        end
      end

      defp get_opt(key, default) when is_list(key) do
        get_in(@compile_opts, key) ||
          :bridge_ex
          |> Application.get_env(__MODULE__, [])
          |> get_in(key) || default
      end

      # Mandatory opts
      defp endpoint, do: get_opt(:endpoint) || raise("Endpoint must be configured!")

      # Optional opts
      defp auth0_audience, do: get_opt([:auth0, :audience])
      defp auth0_enabled?, do: get_opt([:auth0, :enabled], false)
      defp decode_keys, do: get_opt(:decode_keys, :atoms)
      defp encode_variables?, do: get_opt(:encode_variables?, false)
      defp format_variables?, do: get_opt(:format_variables?, false)
      defp format_response?, do: get_opt(:format_response?, false)
      defp http_options, do: get_opt(:http_options, [])
      defp http_headers, do: get_opt(:http_headers, %{})
      defp log_options, do: get_opt(:log_options, [])
      defp max_attempts, do: get_opt(:max_attempts, 1)

      @doc """
      Run a graphql query or mutation over the configured bridge.

      ## Options

        * `options`: extra HTTP options to be passed to Telepoison.
        * `headers`: extra HTTP headers.
        * `endpoint`: override the default endpoint.
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
              opts :: Keyword.t()
            ) :: Client.bridge_response()
      def call(query, variables, opts \\ []) do
        http_options = Keyword.merge(http_options(), Keyword.get(opts, :options, []))
        http_headers = Map.merge(http_headers(), Keyword.get(opts, :headers, %{}))
        max_attempts = Keyword.get(opts, :max_attempts, max_attempts())

        retry_options =
          opts
          |> Keyword.get(:retry_options, [])
          |> then(&Keyword.merge([max_retries: max_attempts - 1], &1))

        with {:ok, http_headers} <- with_authorization_headers(http_headers) do
          endpoint()
          |> Client.call(
            query,
            variables,
            options: http_options,
            headers: http_headers,
            encode_variables: encode_variables?(),
            log_options: log_options(),
            retry_options: retry_options,
            format_variables: format_variables?(),
            decode_keys: decode_keys()
          )
          |> format_response()
        end
      end

      defp format_response({ret, response}) do
        response =
          if format_response?(),
            do: SnakeCase.format(response),
            else: response

        {ret, response}
      end

      defp with_authorization_headers(headers) do
        if auth0_enabled?() do
          unless auth0_audience() do
            raise """
            Auth0 is enabled but audience is not set for bridge in module #{__MODULE__}.
            Please either set an audience for this bridge or disable auth0 locally:

              # Either this
              use BridgeEx.Graphql, auth0: [audience: "my-audience"]
              # or as config...
              config :bridge_ex, #{__MODULE__}, auth0: [audience: "my-audience"]

              # or this
              use BridgeEx.Graphql, auth0: [enabled: false]
              # or as config...
              config :bridge_ex, #{__MODULE__}, auth0: [enabled: false]
            """
          end

          unless Code.ensure_loaded?(PrimaAuth0Ex) do
            raise """
            Auth0 is enabled but :prima_auth0_ex is not loaded. Did you add it to your dependencies?
            """
          end

          with {:ok, authorization_headers} <-
                 Auth0AuthorizationProvider.authorization_headers(auth0_audience()) do
            {:ok, Enum.into(authorization_headers, headers)}
          end
        else
          {:ok, headers}
        end
      end
    end
  end
end
