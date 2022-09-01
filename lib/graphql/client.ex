defmodule BridgeEx.Graphql.Client do
  @moduledoc """
  Graphql client for BridgeEx.
  """

  require Logger

  alias BridgeEx.Graphql.Utils
  alias BridgeEx.Graphql.Retry
  alias BridgeEx.Graphql.Formatter.CamelCase

  @type bridge_response ::
          {:ok, term()}
          | {:error, {:bad_response, integer()}}
          | {:error, {:http_error, String.t()}}
          | {:error, list()}

  @http_options timeout: 1_000, recv_timeout: 16_000
  @http_headers %{
    "Content-type" => "application/json"
  }

  @doc """
  Calls a GraphQL endpoint

  ## Parameters

    * `url`: URL of the endpoint.
    * `query`: Graphql query or mutation.
    * `variables`: variables for Graphql query or mutation.
    * `opts`: various options.

  ## Options

    * `options`: extra HTTP options to be passed to Telepoison.
    * `headers`: extra HTTP headers.
    * `encode_variables`: whether to JSON encode variables or not.
    * `retry_options`: configures retry attempts. Takes the form of `[max_retries: 1, timing: :exponential]`
    * `log_options`: configures logging on errors. Takes the form of `[log_query_on_error: false, log_response_on_error: false]`.
  """
  @deprecated "This call uses `Json.decode` with `keys: :atoms` which is discouraged as it dynamically creates atoms which are not garbage collected. Please use `call/5` with a decoder instead. For instance, you can use `Client.call(url, query, variables, &Utils.string_decoder/1, opts)` which will be the default behavior in the future."
  @spec call(
          url :: String.t(),
          query :: String.t(),
          variables :: map(),
          opts :: Keyword.t()
        ) :: bridge_response()
  def call(url, query, variables, opts),
    do: call(url, query, variables, &Utils.atom_decoder/1, opts)

  @doc """
  Calls a GraphQL endpoint and decodes the response

  ## Parameters

    * `url`: URL of the endpoint.
    * `query`: Graphql query or mutation.
    * `variables`: variables for Graphql query or mutation.
    * `decoder`: decoder for the response. Takes the form of `(String.t() -> client_response())`, several decoders are provided in the `BridgeEx.Graphql.Utils` module.
    * `opts`: various options.

  ## Options

    * `options`: extra HTTP options to be passed to Telepoison.
    * `headers`: extra HTTP headers.
    * `encode_variables`: whether to JSON encode variables or not.
    * `retry_options`: configures retry attempts. Takes the form of `[max_retries: 1, timing: :exponential]`
    * `log_options`: configures logging on errors. Takes the form of `[log_query_on_error: false, log_response_on_error: false]`.
  """
  @spec call(
          url :: String.t(),
          query :: String.t(),
          variables :: map(),
          decoder :: (String.t() -> bridge_response()),
          opts :: Keyword.t()
        ) :: bridge_response()
  def call(
        url,
        query,
        variables,
        decoder,
        opts
      ) do
    encode_variables = Keyword.get(opts, :encode_variables, false)
    http_options = Keyword.merge(@http_options, Keyword.get(opts, :options, []))
    http_headers = Map.merge(@http_headers, Keyword.get(opts, :headers, %{}))
    log_options = Keyword.merge(log_options(), Keyword.get(opts, :log_options, []))
    format_variables = Keyword.get(opts, :format_variables, false)

    retry_options =
      opts
      |> Keyword.get(:retry_options, [])
      |> then(
        &Keyword.merge(
          [
            delay: 100,
            max_retries: 0,
            policy: fn _ -> true end,
            timing: :exponential
          ],
          &1
        )
      )

    variables =
      variables
      |> do_format_variables(format_variables)
      |> do_encode_variables(encode_variables)

    %{query: String.trim(query), variables: variables}
    |> Jason.encode()
    |> Noether.Either.bind(
      &Retry.retry(
        &1,
        fn query ->
          url
          |> Telepoison.post(query, http_headers, http_options)
          |> Utils.decode_http_response(query, decoder, log_options)
          |> Utils.parse_response()
        end,
        retry_options
      )
    )
  end

  defp log_options do
    global_log_options = Application.get_env(:bridge_ex, :log_options, [])

    if length(global_log_options) != 0 do
      Logger.warning(
        "Global log_options is deprecated and will be removed in the future, please use the local ones"
      )
    end

    Keyword.merge(
      [log_query_on_error: false, log_response_on_error: false],
      global_log_options
    )
  end

  @spec do_format_variables(any(), bool()) :: any
  defp do_format_variables(variables, true), do: CamelCase.format(variables)
  defp do_format_variables(variables, false), do: variables

  @spec do_encode_variables(any(), bool()) :: any()
  defp do_encode_variables(variables, true), do: Jason.encode!(variables)
  defp do_encode_variables(variables, false), do: variables
end
