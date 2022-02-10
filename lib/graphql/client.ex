defmodule BridgeEx.Graphql.Client do
  @moduledoc """
  Documentation for `BridgeEx`.
  """

  alias BridgeEx.Graphql.Utils

  @type bridge_response :: {:ok, term()} | {:error, String.t()}

  @doc """
  Calls a GraphQL endpoint

  ## Options

    * `:options` - HTTPoison options
    * `:headers` - HTTPoison headers
    * `:max_attempts` - Defines number of retries before returning error
  """

  @spec call(
          url :: String.t(),
          query :: String.t(),
          variables :: map(),
          http_options :: Keyword.t(),
          http_headers :: map(),
          max_attempts :: integer(),
          log_options :: Keyword.t()
        ) :: bridge_response()
  def call(
        url,
        query,
        variables,
        http_options,
        http_headers,
        max_attempts,
        log_options
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
      max_attempts
    )
  end

  @doc """
  formats a GraphQL query response to make it Absinthe compliant
  """
  @spec format_response(%{atom() => any()} | [%{atom() => any()}]) ::
          %{atom() => any()} | [%{atom() => any()}]
  def format_response(response) when is_list(response) do
    Enum.map(response, &format_response(&1))
  end

  def format_response(response) when is_map(response), do: Utils.normalize_inner_fields(response)
  def format_response(response), do: response
end
