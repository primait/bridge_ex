defmodule BridgeEx.GraphqlTest do
  use ExUnit.Case, async: false

  doctest BridgeEx.Graphql

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
  test "retries request on status code != 2XX", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
      end)

      Plug.Conn.resp(conn, 500, "")
    end)

    defmodule TestBridgeRetriesOnBadResponse do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql", max_attempts: 2
    end

    assert {:ok, %{key: "value"}} = TestBridgeRetriesOnBadResponse.call("myquery", %{})
  end

  test "retries request on response with errors", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
      end)

      Plug.Conn.resp(
        conn,
        200,
        ~s<{"data": {"key": "value"}, "errors": [{"message": "error1", "extensions": { "code": "BAD_REQUEST" }}, {"message": "error2"}]}>
      )
    end)

    defmodule TestBridgeRetriesOnError do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql", max_attempts: 2
    end

    assert {:ok, %{key: "value"}} = TestBridgeRetriesOnError.call("myquery", %{})
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

  test "reports back graphql structured errors", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/graphql", fn conn ->
      Plug.Conn.resp(
        conn,
        200,
        ~s<{"errors": [{"message": "error1", "extensions": { "code": "BAD_REQUEST" }}, {"message": "error2"}]}>
      )
    end)

    defmodule TestBridgeForErrors do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql"
    end

    assert {:error,
            [%{message: "error1", extensions: %{code: "BAD_REQUEST"}}, %{message: "error2"}]} =
             TestBridgeForErrors.call("myquery", %{})
  end

  @tag capture_log: true
  test "retry_policy correctly prevents retry", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"errors": [{"message": "error"}]}>)
      end)

      Plug.Conn.resp(
        conn,
        500,
        ""
      )
    end)

    retry_policy = fn errors ->
      case errors do
        {:bad_response, _} -> false
        _ -> true
      end
    end

    defmodule TestBridgePreventsRetryWithCustomPolicy do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql"
    end

    assert {:error, {:bad_response, _}} =
             TestBridgePreventsRetryWithCustomPolicy.call("myquery", %{},
               retry_policy: retry_policy,
               max_attempts: 2
             )
  end

  test "retry_policy correctly retries graphql error", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
      end)

      Plug.Conn.resp(
        conn,
        200,
        ~s<{"errors": [{"message": "error", "extensions": {"code":"CODE"}}]}>
      )
    end)

    retry_policy = fn errors ->
      case errors do
        [%{message: "error", extensions: %{code: "CODE"}}] -> true
        _ -> false
      end
    end

    defmodule TestBridgePreventsRetryWithCustomPolicy do
      use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql"
    end

    assert {:ok, %{key: "value"}} =
             TestBridgePreventsRetryWithCustomPolicy.call("myquery", %{},
               retry_policy: retry_policy,
               max_attempts: 2
             )
  end
end
