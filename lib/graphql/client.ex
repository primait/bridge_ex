defmodule BridgeEx.Graphql.Client do
  @moduledoc """
  Graphql client for BridgeEx.
  """

  alias BridgeEx.Graphql.Utils

  @type bridge_response ::
          {:ok, term()}
          | {:error, {:bad_response, integer()}}
          | {:error, {:http_error, String.t()}}
          | {:error, list()}

  @doc """
  Calls a GraphQL endpoint

  ## Parameters

    * `url`: URL of the endpoint.
    * `query`: Graphql query or mutation.
    * `variables`: dariables for Graphql query or mutation.
    * `http_options`: HTTPoison options.
    * `http_headers`: HTTPoison headers.
    * `max_attempts`: defines number of retries before returning error.
    * `log_options`: configures logging on errors. Takes the form of `[log_query_on_error: false, log_response_on_error: false]`.
  """

  @spec call(
          url :: String.t(),
          query :: String.t(),
          variables :: map(),
          http_options :: Keyword.t(),
          http_headers :: map(),
          max_attempts :: integer(),
          log_options :: Keyword.t(),
          retry_policy :: fun()
        ) :: bridge_response()
  def call(
        url,
        query,
        variables,
        http_options,
        http_headers,
        max_attempts,
        log_options,
        retry_policy
      ) do
    %{query: String.trim(query), variables: variables}
    |> Jason.encode()
    |> Utils.retry(
      fn query ->
        url
        |> Telepoison.post(query, http_headers, http_options)
        |> Utils.decode_http_response(query, log_options)
        |> Utils.parse_response()
      end,
      retry_policy,
      max_attempts
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
end
