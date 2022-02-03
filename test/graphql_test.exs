defmodule BridgeEx.GraphqlTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

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
    set_auth0_configuration(bypass.port)
    reload_app()
    on_exit(&reload_app/0)

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

  test "supports custom headers", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/graphql", fn conn ->
      assert {"content-type", "application/json"} in conn.req_headers
      assert {"custom-header-key", "custom-header-value"} in conn.req_headers
      Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
    end)

    defmodule TestBridgeWithCustomHeaders do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql"
    end

    TestBridgeWithCustomHeaders.call("myquery", %{},
      headers: %{"custom-header-key" => "custom-header-value"}
    )
  end

  test "reports back graphql errors", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/graphql", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"errors": [{"message": "error1"}, {"message": "error2"}]}>)
    end)

    defmodule TestBridgeForErrors do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql"
    end

    assert {:error, "error1, error2"} = TestBridgeForErrors.call("myquery", %{})
  end

  test "on non-200 status code, by default, does not log request_body and body_string as metadata",
       %{
         bypass: bypass
       } do
    Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
      Plug.Conn.resp(conn, 500, "some 500 error")
    end)

    defmodule TestBridgeForErrorsNoLogs do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql"
    end

    err_log =
      capture_log([metadata: [:request_body, :body_string]], fn ->
        TestBridgeForErrorsNoLogs.call("myquery", %{})
      end)

    assert err_log =~ "GraphQL: Bad Response error"
    assert not (err_log =~ "request_body=")
    assert not (err_log =~ "body_string=")
  end

  test "on non-200 status code logs request_body and body_string if respective options are enabled",
       %{
         bypass: bypass
       } do
    Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
      Plug.Conn.resp(conn, 500, "some 500 error")
    end)

    defmodule TestForErrorsAllLogs do
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        log_options: [log_query_on_error: true, log_response_on_error: true]
    end

    err_log =
      capture_log([metadata: [:request_body, :body_string]], fn ->
        TestForErrorsAllLogs.call("myquery", %{})
      end)

    assert err_log =~ "GraphQL: Bad Response error"
    assert err_log =~ "request_body="
    assert err_log =~ "body_string="
  end

  defp valid_auth0_response do
    ~s<{"access_token":"#{@fake_jwt}","expires_in":86400,"token_type":"Bearer"}>
  end

  defp set_test_env(app, key, new_value) do
    previous_value = Application.get_env(app, key)
    Application.put_env(app, key, new_value)
    on_exit(fn -> Application.put_env(app, key, previous_value) end)
  end

  defp reload_app do
    Application.stop(:bridge_ex)
    Application.start(:bridge_ex)
  end

  defp set_auth0_configuration(port) do
    set_test_env(:bridge_ex, :auth0_enabled, true)
    set_test_env(:prima_auth0_ex, :auth0_base_url, "http://localhost:#{port}")
    set_test_env(:prima_auth0_ex, :client, client_id: "", client_secret: "", cache_enabled: false)
  end
end
