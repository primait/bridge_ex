defmodule BridgeEx.Graphql.Utils do
  @moduledoc """
  Misc utils for handling Graphql requests/responses.
  """

  alias BridgeEx.Graphql.LanguageConventions
  require Logger

  @type client_response :: {:ok, any()} | {:error, any()}
  @type graphql_response :: {:ok, %{String.t() => term()}} | {:error, String.t()}

  @spec decode_http_response(
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()},
          String.t()
        ) :: client_response()
  def decode_http_response({:ok, %HTTPoison.Response{status_code: 200, body: body_string}}, _) do
    Jason.decode(body_string)
  end

  def decode_http_response(
        {:ok,
         %HTTPoison.Response{status_code: code, body: body_string, request_url: request_url}},
        query
      ) do
    Logger.error("GraphQL: Bad Response error",
      status_code: code,
      body_string: body_string,
      request_url: request_url,
      request_body: query
    )

    {:error, "BAD_RESPONSE"}
  end

  def decode_http_response({:error, %HTTPoison.Error{reason: reason}}, query) do
    Logger.error("GraphQL: HTTP error", reason: inspect(reason), request_body: query)

    {:error, "HTTP_ERROR"}
  end

  @spec parse_response(client_response()) :: graphql_response()
  def parse_response({:error, error}) when is_binary(error), do: {:error, error}

  def parse_response({:ok, %{errors: errors}}) do
    errors =
      errors
      |> Enum.map(& &1.message)
      |> Enum.join(", ")

    {:error, errors}
  end

  def parse_response({:ok, %{"data" => data}}), do: {:ok, data}

  @spec normalize_inner_fields(%{atom() => any()} | String.t()) :: %{atom() => any()} | String.t()
  def normalize_inner_fields(binary) when is_binary(binary), do: binary
  def normalize_inner_fields(map = %{}), do: Enum.reduce(map, %{}, &do_normalize_inner_fields/2)

  @spec retry(
          {:ok, String.t()} | {:error, Jason.EncodeError.t() | Exception.t()},
          (any() -> {:error, String.t()} | {:ok, any()}),
          integer()
        ) :: client_response()
  def retry({:error, %Jason.EncodeError{message: message}}, _fun, _attempt) do
    {:error, message}
  end

  def retry({:ok, arg}, fun, 1) do
    fun.(arg)
  end

  def retry({:ok, arg}, fun, n) do
    case fun.(arg) do
      {:error, _reason} ->
        Process.sleep(500)
        retry({:ok, arg}, fun, n - 1)

      val ->
        val
    end
  end

  @spec do_normalize_inner_fields({String.t(), any()}, map()) :: %{String.t() => any()}
  defp do_normalize_inner_fields({key, value}, acc) when is_map(value) do
    Map.merge(acc, %{to_snake_case(key) => normalize_inner_fields(value)})
  end

  defp do_normalize_inner_fields({key, value}, acc) when is_list(value) do
    Map.merge(acc, %{to_snake_case(key) => Enum.map(value, &normalize_inner_fields/1)})
  end

  defp do_normalize_inner_fields({key, value}, acc) do
    Map.merge(acc, %{to_snake_case(key) => value})
  end

  @spec to_snake_case(String.t()) :: String.t()
  defp to_snake_case(formattable) when is_binary(formattable),
    do: LanguageConventions.to_internal_name(formattable, :read)
end
