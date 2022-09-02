defmodule BridgeEx.ConfigValidationTest do
  use ExUnit.Case, async: false

  doctest BridgeEx.Graphql

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  # This test doesn't play nice with others and apparently needs to be on his own, otherwise flakiness ensues.
  # We investigated this issue for quite some time but this is the only solution we could come up with :(
  test "macro won't expand if auth0 is enabled but no audience is set", %{bypass: bypass} do
    assert_raise RuntimeError, fn ->
      defmodule TestBridgeWithAuth0EnabledButNoAudience do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          auth0: [enabled: true],
          decoder: :atoms
      end
    end
  end
end
