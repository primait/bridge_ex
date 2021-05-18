defmodule BridgeEx.Graphql.Client do
  @moduledoc """
  Documentation for `BridgeEx`.
  """

  require Logger
  alias BridgeEx.Graphql.Utils

  @type bridge_response :: {:ok, term()} | {:error, String.t()}

  @type graphql_response ::
          {:error, String.t()}
          | {:ok, %{data: term()}}
          | {
              :ok,
              %{
                error: [
                  %{message: String.t(), locations: [%{line: integer(), column: integer()}]}
                ],
                data: term()
              }
            }

  @doc """
  Calls a GraphQL endpoint

  ## Options

    * `:options` - HTTPoison options

    * `:headers` - HTTPoison headers

    * `:max_attempts` - Defines number of retries before returning error
  """

  # @spec call!(String.t(), String.t(), map(), Keyword.t()) :: term()
  # def call!(graphql_url, query, variables, options \\ []) do
  #   case call(graphql_url, query, variables, options) do
  #     {:ok, data} -> data
  #     {:error, error} -> raise error
  #   end
  # end

  @spec call(
          url :: String.t(),
          query :: String.t(),
          variables :: map(),
          http_options :: Keyword.t(),
          http_headers :: map(),
          max_attempts :: integer()
        ) :: bridge_response()
  def call(url, query, variables, http_options, http_headers, max_attempts) do
    do_call(
      %{query: String.trim(query), variables: Jason.encode!(variables)},
      url,
      http_options,
      http_headers,
      max_attempts
    )
  end

  @spec call_no_variables_encoding(
          url :: String.t(),
          query :: String.t(),
          variables :: map(),
          http_options :: Keyword.t(),
          http_headers :: map(),
          max_attempts :: integer()
        ) ::
          bridge_response()
  def call_no_variables_encoding(url, query, variables, http_options, http_headers, max_attempts) do
    do_call(
      %{query: String.trim(query), variables: variables},
      url,
      http_options,
      http_headers,
      max_attempts
    )
  end

  defp do_call(query_and_variables, url, http_options, http_headers, max_attempts) do
    query_and_variables
    |> Jason.encode()
    |> Utils.retry(
      fn query ->
        url
        |> Telepoison.post(query, http_headers, http_options)
        |> Utils.decode_response(query)
        |> Utils.parse_response()
      end,
      max_attempts
    )
  end

  @spec handle_response({:ok, any()} | {:error, any()}, String.t()) ::
          {:ok, any()} | {:error, any()}
  def handle_response(response, service_name) do
    case response do
      {:error, error} ->
        Logger.error("#{service_name}: api call error", message: error)
        {:error, error}

      {:ok, %{error: error}} ->
        {:error, error}

      val ->
        val
    end
  end

  @doc """
  formats a GraphQL query response to make it Absinthe compliant
  """
  @spec format_response(%{atom() => any()} | [%{atom() => any()}]) ::
          %{atom() => any()} | [%{atom() => any()}]
  def format_response(response) when is_list(response) do
    Enum.map(response, &format_response(&1))
  end

  def format_response(response), do: Utils.normalize_inner_fields(response)
end
