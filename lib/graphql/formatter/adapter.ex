defmodule BridgeEx.Graphql.Formatter.Adapter do
  @moduledoc """
  Behaviour used to implement a formatter adapter which could be used to
  format types for both input variables and responses.

  ```elixir
  defmodule MyCustomAdapter do

    @behaviour BridgeEx.Graphql.Formatter.Adapter

    def format(variable) when is_map(variable) do
      variable
      |> Enum.map(fn
        {key, value} -> {key, format(value)}
      end)
      |> Map.new()
    end

    def format(variable = %Date{}), do: Date.to_string(variable)
  end

  defmodule MyBridge do
    use BridgeEx.Graphql,
      variable_types_formatter: MyCustomAdapter
  end
  ```
  """

  @type t() :: %__MODULE__{}

  defstruct do [
      name: __MODULE__
    ]
  end

  @callback format(any()) :: any()
end
