defmodule BridgeEx.GraphqlTest do
  use ExUnit.Case, async: false

  doctest BridgeEx.Graphql

  @fake_jwt "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im15X2tpZCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxMjMsImV4cCI6MTIzMTIzMTIzfQ.qq5yV_Lr6BHOgq5-oWk91Y6F26awQ-82Nn9__7-w9Xg"

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "runs graphql queries over the provided endpoint", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/graphql", fn conn ->
      Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
    end)

    defmodule TestSimpleBridge do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql"
    end

    assert {:ok, %{key: "value"}} = TestSimpleBridge.call("myquery", %{})
  end

  @tag capture_log: true
  test "retries request on failure", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
      end)

      Plug.Conn.resp(conn, 500, "")
    end)

    defmodule TestBridgeWithRetry do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql", max_attempts: 2
    end

    assert {:ok, %{key: "value"}} = TestBridgeWithRetry.call("myquery", %{})
  end

  test "authenticates via auth0 when auth0_audience is set", %{bypass: bypass} do
    set_auth0_ex_configuration(bypass.port)
    reload_auth0_ex()

    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      Plug.Conn.resp(conn, 200, valid_auth0_response())
    end)

    Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
      assert {"authorization", "Bearer #{@fake_jwt}"} in conn.req_headers
      Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
    end)

    defmodule TestBridgeWithAuth0 do
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        auth0: [audience: "my-audience", enabled: true]
    end

    assert {:ok, %{key: "value"}} = TestBridgeWithAuth0.call("myquery", %{})
  end

  defp valid_auth0_response do
    ~s<{"access_token":"#{@fake_jwt}","expires_in":86400,"token_type":"Bearer"}>
  end

  defp set_test_env(app, key, new_value) do
    previous_value = Application.get_env(app, key)
    Application.put_env(app, key, new_value)
    on_exit(fn -> Application.put_env(app, key, previous_value) end)
  end

  defp reload_auth0_ex do
    Application.stop(:auth0_ex)
    Application.start(:auth0_ex)
  end

  defp set_auth0_ex_configuration(port) do
    set_test_env(:auth0_ex, :auth0_base_url, "http://localhost:#{port}")
    set_test_env(:auth0_ex, :client, client_id: "", client_secret: "", cache_enabled: false)
  end
end
