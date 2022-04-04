defmodule BridgeEx.Graphql.Utils do
  @moduledoc """
  Misc utils for handling Graphql requests/responses.
  """

  alias BridgeEx.Graphql.LanguageConventions
  require Logger

  @type client_response :: {:ok, any()} | {:error, any()}

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

  @spec decode_http_response(
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()},
          String.t(),
          Keyword.t()
        ) :: client_response()
  def decode_http_response({:ok, %HTTPoison.Response{status_code: 200, body: body_string}}, _, _) do
    Jason.decode(body_string, keys: :atoms)
  end

  def decode_http_response(
        {:ok,
         %HTTPoison.Response{status_code: code, body: body_string, request_url: request_url}},
        query,
        log_options
      ) do
    log_response_on_error = Keyword.get(log_options, :log_response_on_error, false)
    log_query_on_error = Keyword.get(log_options, :log_query_on_error, false)

    metadata =
      [status_code: code, request_url: request_url]
      |> prepend_if(log_response_on_error, {:body_string, body_string})
      |> prepend_if(log_query_on_error, {:request_body, query})

    Logger.error("GraphQL: Bad Response error", metadata)

    {:error, {:bad_response, code}}
  end

  def decode_http_response(
        {:error, %HTTPoison.Error{reason: reason}},
        query,
        log_options
      ) do
    log_query_on_error = Keyword.get(log_options, :log_query_on_error, false)
    metadata = prepend_if([reason: inspect(reason)], log_query_on_error, {:request_body, query})
    Logger.error("GraphQL: HTTP error", metadata)

    {:error, {:http_error, reason}}
  end

  @spec parse_response(graphql_response()) :: client_response()
  def parse_response({:error, error}), do: {:error, error}

  def parse_response({:ok, %{errors: errors}}), do: {:error, errors}

  def parse_response({:ok, %{data: data}}), do: {:ok, data}

  @spec normalize_inner_fields(%{atom() => any()} | String.t()) :: %{atom() => any()} | String.t()
  def normalize_inner_fields(binary) when is_binary(binary), do: binary
  def normalize_inner_fields(number) when is_number(number), do: number
  def normalize_inner_fields(boolean) when is_boolean(boolean), do: boolean
  def normalize_inner_fields(map = %{}), do: Enum.reduce(map, %{}, &do_normalize_inner_fields/2)
  @spec do_normalize_inner_fields({atom(), any()}, map()) :: %{atom() => any()}
  defp do_normalize_inner_fields({key, value}, acc) when is_map(value) do
    Map.merge(acc, %{to_snake_case(key) => normalize_inner_fields(value)})
  end

  defp do_normalize_inner_fields({key, value}, acc) when is_list(value) do
    Map.merge(acc, %{to_snake_case(key) => Enum.map(value, &normalize_inner_fields/1)})
  end

  defp do_normalize_inner_fields({key, value}, acc) do
    Map.merge(acc, %{to_snake_case(key) => value})
  end

  @spec to_snake_case(atom() | String.t()) :: atom() | String.t()
  defp to_snake_case(formattable) when is_binary(formattable),
    do: LanguageConventions.to_internal_name(formattable, :read)

  defp to_snake_case(formattable) when is_atom(formattable) do
    formattable
    |> Atom.to_string()
    |> LanguageConventions.to_internal_name(:read)
    |> String.to_atom()
  end

  defp prepend_if(list, false, _), do: list
  defp prepend_if(list, true, value), do: [value | list]
end
