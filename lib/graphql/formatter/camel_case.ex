defmodule BridgeEx.Graphql.Formatter.CamelCase do
  @behaviour BridgeEx.Graphql.Formatter.Adapter

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
    |> Absinthe.Utils.camelize(lower: true)
    |> String.to_atom()
  end

  defp format_key(key) when is_binary(key) do
    Absinthe.Utils.camelize(key, lower: true)
  end

  defp format_key(key), do: key
end
