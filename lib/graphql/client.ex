defmodule BridgeEx.Graphql.Client do
  @moduledoc """
  Graphql client for BridgeEx.
  """

  require Logger

  alias BridgeEx.Graphql.Utils
  alias BridgeEx.Graphql.Retry
  alias BridgeEx.Graphql.Formatter.Adapter
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

  @spec call(
          url :: String.t(),
          query :: String.t(),
          variables :: map(),
          opts :: Keyword.t()
        ) :: bridge_response()
  def call(
        url,
        query,
        variables,
        opts
      ) do
    encode_variables = Keyword.get(opts, :encode_variables, false)
    http_options = Keyword.merge(@http_options, Keyword.get(opts, :options, []))
    http_headers = Map.merge(@http_headers, Keyword.get(opts, :headers, %{}))
    log_options = Keyword.merge(log_options(), Keyword.get(opts, :log_options))
    format_variables = Keyword.get(opts, :format_variables, false)
    variables_formatter = Keyword.get(opts, :variables_formatter, nil)

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
      |> do_format_variables(variables_formatter)
      |> do_encode_variables(encode_variables)

    %{query: String.trim(query), variables: variables}
    |> Jason.encode()
    |> Noether.Either.bind(
      &Retry.retry(
        &1,
        fn query ->
          url
          |> Telepoison.post(query, http_headers, http_options)
          |> Utils.decode_http_response(query, log_options)
          |> Utils.parse_response()
        end,
        retry_options
      )
    )
  end

  defp log_options do
    Application.get_env(:bridge_ex, :log_options,
      log_query_on_error: false,
      log_response_on_error: false
    )
  end

  @spec do_format_variables(any(), bool() | Adapter.t()) :: any
  def do_format_variables(variables, true), do: CamelCase.format(variables)
  def do_format_variables(variables, false), do: variables

  def do_format_variables(variables, formatter) when not is_nil(formatter) do
    try do
      formatter.format(variables)
    rescue
      e ->
        Logger.error("Formatter #{formatter.name} error", e)
        e
    end
  end

  def do_format_variables(variables, _), do: variables

  @spec do_encode_variables(any(), bool()) :: any()
  def do_encode_variables(variables, true), do: Jason.encode!(variables)
  def do_encode_variables(variables, _), do: variables
end
