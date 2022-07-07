defmodule BridgeEx.Graphql.Formatter.SnakeCase do
  @moduledoc """
  Formatter to format map keys to snake_case.
  """

  @behaviour BridgeEx.Graphql.Formatter.Adapter

  alias BridgeEx.Graphql.LanguageConventions

  @spec format(map()) :: map()
  def format(variable) when is_map(variable) do
    variable
    |> Enum.map(fn
      {key, value} -> {format_key(key), format(value)}
    end)
    |> Map.new()
  end

  def format(variable) when is_list(variable) do
    Enum.map(variable, &format(&1))
  end

  def format(variable), do: variable

  defp format_key(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> format_key()
    |> String.to_atom()
  end

  defp format_key(key) when is_binary(key) do
    to_snake_case(key)
  end

  defp format_key(key), do: key

  @spec to_snake_case(String.t()) :: atom() | String.t()
  defp to_snake_case(formattable) when is_binary(formattable),
    do: LanguageConventions.to_internal_name(formattable, :read)
end
