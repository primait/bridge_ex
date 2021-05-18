defmodule BridgeEx.Example.SomeService do
  @moduledoc """
  Bridge definition for SomeService
  """

  @callback my_cool_query(any()) :: boolean()
end
