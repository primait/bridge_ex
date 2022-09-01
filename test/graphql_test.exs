defmodule BridgeEx.GraphqlTest do
  use ExUnit.Case, async: false

  doctest BridgeEx.Graphql

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  @tag capture_log: true
  test "[DEPRECATED] retries using max_attempts", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
      end)

      Plug.Conn.resp(conn, 500, "")
    end)

    defmodule TestBridgeDeprecatedOption do
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        decoder: &BridgeEx.Graphql.Utils.atom_decoder/1,
        max_attempts: 2
    end

    assert {:ok, %{key: "value"}} = TestBridgeDeprecatedOption.call("myquery", %{})
  end

  test "runs graphql queries over the provided endpoint", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/graphql", fn conn ->
      Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
    end)

    defmodule TestSimpleBridge do
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        decoder: &BridgeEx.Graphql.Utils.atom_decoder/1
    end

    assert {:ok, %{key: "value"}} = TestSimpleBridge.call("myquery", %{})
  end

  test "runs graphql queries over the provided endpoint, decoding as strings", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/graphql", fn conn ->
      Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
    end)

    defmodule TestSimpleBridgeStrings do
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        decoder: &BridgeEx.Graphql.Utils.string_decoder/1
    end

    assert {:ok, %{"key" => "value"}} = TestSimpleBridgeStrings.call("myquery", %{})
  end

  test "runs graphql queries over the provided endpoint, decoding as existing atoms", %{
    bypass: bypass
  } do
    Bypass.expect(bypass, "POST", "/graphql", fn conn ->
      Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
    end)

    defmodule TestSimpleBridgeExistingAtoms do
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        decoder: &BridgeEx.Graphql.Utils.existing_atom_decoder/1
    end

    assert {:ok, %{key: "value"}} = TestSimpleBridgeExistingAtoms.call("myquery", %{})
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
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        decoder: &BridgeEx.Graphql.Utils.atom_decoder/1
    end

    assert {:ok, %{key: "value"}} =
             TestBridgeRetriesOnBadResponse.call("myquery", %{}, retry_options: [max_retries: 1])
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
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        decoder: &BridgeEx.Graphql.Utils.atom_decoder/1
    end

    assert {:ok, %{key: "value"}} =
             TestBridgeRetriesOnError.call("myquery", %{}, retry_options: [max_retries: 1])
  end

  test "supports custom headers", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/graphql", fn conn ->
      assert {"content-type", "application/json"} in conn.req_headers
      assert {"custom-header-key", "custom-header-value"} in conn.req_headers
      Plug.Conn.resp(conn, 200, ~s[{"data": {"key": "value"}}])
    end)

    defmodule TestBridgeWithCustomHeaders do
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        decoder: &BridgeEx.Graphql.Utils.atom_decoder/1
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
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        decoder: &BridgeEx.Graphql.Utils.atom_decoder/1
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
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        decoder: &BridgeEx.Graphql.Utils.atom_decoder/1
    end

    assert {:error, {:bad_response, _}} =
             TestBridgePreventsRetryWithCustomPolicy.call("myquery", %{},
               retry_options: [policy: retry_policy, max_retries: 1]
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

    defmodule TestBridgeRetriesWithGivenPolicy do
      use BridgeEx.Graphql,
        endpoint: "http://localhost:#{bypass.port}/graphql",
        decoder: &BridgeEx.Graphql.Utils.atom_decoder/1
    end

    assert {:ok, %{key: "value"}} =
             TestBridgeRetriesWithGivenPolicy.call("myquery", %{},
               retry_options: [policy: retry_policy, max_retries: 1]
             )
  end
end
