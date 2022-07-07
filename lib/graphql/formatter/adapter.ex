defmodule BridgeEx.Graphql.Formatter.Adapter do
  @moduledoc """
  Behaviour used to implement a formatter adapter which could be used to
  format types for both input variables and responses.
  ```
  """

  @callback format(any()) :: any()
end
