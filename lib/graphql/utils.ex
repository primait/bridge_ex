defmodule BridgeEx.Graphql.Utils do
  @moduledoc """
  Misc utils for handling Graphql requests/responses.
  """

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
          (String.t() -> client_response()),
          Keyword.t()
        ) :: client_response()
  def decode_http_response(
        {:ok, %HTTPoison.Response{status_code: 200, body: body_string}},
        _,
        decoder,
        _
      ) do
    decoder.(body_string)
  end

  def decode_http_response(
        {:ok,
         %HTTPoison.Response{status_code: code, body: body_string, request_url: request_url}},
        query,
        _,
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
        _,
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
  def parse_response({:ok, %{"errors" => errors}}), do: {:error, errors}

  def parse_response({:ok, %{data: data}}), do: {:ok, data}
  def parse_response({:ok, %{"data" => data}}), do: {:ok, data}

  def atom_decoder(body), do: Jason.decode(body, keys: :atoms)
  def existing_atom_decoder(body), do: Jason.decode(body, keys: :atoms!)
  def string_decoder(body), do: Jason.decode(body)

  def json_decoder(:atoms), do: &atom_decoder/1
  def json_decoder(:existing_atoms), do: &existing_atom_decoder/1
  def json_decoder(:strings), do: &string_decoder/1

  defp prepend_if(list, false, _), do: list
  defp prepend_if(list, true, value), do: [value | list]
end
