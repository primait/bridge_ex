defmodule BridgeEx.GraphqlTest do
  use ExUnit.Case, async: true
  doctest BridgeEx.Graphql

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "runs graphql queries over the provided endpoint", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/graphql", fn conn ->
      Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
    end)

    defmodule TestBridge do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql"
    end

    assert {:ok, %{key: "value"}} = TestBridge.call("myquery", %{})
  end
end
