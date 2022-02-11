defmodule BridgeEx.ConfigValidationTest do
  use ExUnit.Case, async: false

  import BridgeEx.TestHelper

  doctest BridgeEx.Graphql

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  # This test doesn't play nice with others and apparently needs to be on his own, otherwise flakiness ensues.
  # We investigated this issue for quite some time but this is the only solution we could come up with :(
  test "macro won't expand if auth0 is enabled but no audience is set", %{bypass: bypass} do
    set_auth0_configuration(bypass.port)
    reload_app()
    on_exit(&reload_app/0)

    assert_raise CompileError, fn ->
      defmodule TestBridgeWithAuth0EnabledButNoAudience do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          auth0: [enabled: true]
      end
    end
  end
end
