defmodule BridgeEx.Graphql.Client do
  @moduledoc """
  Graphql client for BridgeEx.
  """

  alias BridgeEx.Graphql.Utils
  alias BridgeEx.Graphql.Retry

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
      if encode_variables,
        do: Jason.encode!(variables),
        else: variables

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

  @doc """
  Formats a GraphQL query response to make it Absinthe compliant
  """
  @spec format_response(%{atom() => any()} | [%{atom() => any()}]) ::
          %{atom() => any()} | [%{atom() => any()}]
  def format_response(response) when is_list(response) do
    Enum.map(response, &format_response(&1))
  end

  def format_response(response) when is_map(response), do: Utils.normalize_inner_fields(response)
  def format_response(response), do: response

  defp log_options do
    Application.get_env(:bridge_ex, :log_options,
      log_query_on_error: false,
      log_response_on_error: false
    )
  end

  @doc """
  Formats Graphql query variables to make it compliant with the Schema
  """
  def format_variables(nil), do: nil
  @spec format_variables(any) :: any
  def format_variables(variable = %Date{}), do: Date.to_string(variable)
  def format_variables(variable = %DateTime{}), do: DateTime.to_string(variable)
  def format_variables(variable = %NaiveDateTime{}), do: NaiveDateTime.to_string(variable)
  def format_variables(variable) when is_boolean(variable), do: variable

  def format_variables(variable) when is_map(variable) do
    variable
    |> Enum.map(fn
      {key, value} when is_atom(key) ->
        {key |> Atom.to_string() |> Absinthe.Utils.camelize(lower: true), format_variables(value)}

      {key, value} when is_binary(key) ->
        {Absinthe.Utils.camelize(key, lower: true), format_variables(value)}
    end)
    |> Map.new()
  end

  def format_variables(variable) when is_atom(variable),
    do: variable |> Atom.to_string() |> String.upcase()

  def format_variables(variable) when is_list(variable),
    do: Enum.map(variable, &format_variables(&1))

  def format_variables(variables), do: variables
end
