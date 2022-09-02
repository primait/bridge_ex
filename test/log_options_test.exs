defmodule BridgeEx.LogOptionsTest do
  use ExUnit.Case, async: false

  import BridgeEx.TestHelper
  import ExUnit.CaptureLog

  doctest BridgeEx.Graphql

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "when endpoint returns non-200 status code" do
    test "by default, does not log request_body and body_string as metadata",
         %{
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 500, "some 500 error")
      end)

      defmodule TestBridgeForErrorsNoLogs do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          decoder: :atoms
      end

      err_log =
        capture_log([metadata: [:request_body, :body_string]], fn ->
          TestBridgeForErrorsNoLogs.call("myquery", %{})
        end)

      assert err_log =~ "GraphQL: Bad Response error"
      assert not (err_log =~ "request_body=")
      assert not (err_log =~ "body_string=")
    end

    test "logs request_body and body_string if respective options are enabled locally",
         %{
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 500, "some 500 error")
      end)

      defmodule TestForErrorsAllLogsLocal do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          log_options: [log_query_on_error: true, log_response_on_error: true],
          decoder: :atoms
      end

      err_log =
        capture_log([metadata: [:request_body, :body_string]], fn ->
          TestForErrorsAllLogsLocal.call("myquery", %{})
        end)

      assert err_log =~ "GraphQL: Bad Response error"
      assert err_log =~ "request_body="
      assert err_log =~ "body_string="
    end

    test "logs request_body and body_string if respective options are enabled globally",
         %{
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 500, "some 500 error")
      end)

      set_log_options_configuration(log_query?: true, log_response?: true)
      reload_app(_start_prima_auth0_ex? = false)
      on_exit(fn -> reload_app(_start_prima_auth0_ex? = false) end)

      defmodule TestForErrorsAllLogsGlobal do
        use BridgeEx.Graphql, endpoint: "http://localhost:#{bypass.port}/graphql", decoder: :atoms
      end

      err_log =
        capture_log([metadata: [:request_body, :body_string]], fn ->
          TestForErrorsAllLogsGlobal.call("myquery", %{})
        end)

      assert err_log =~ "GraphQL: Bad Response error"
      assert err_log =~ "request_body="
      assert err_log =~ "body_string="
    end

    test "does not log request_body and body_string if respective options are explicitly disabled locally",
         %{
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 500, "some 500 error")
      end)

      defmodule TestForErrorsDisabledLogsLocally do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          log_options: [log_query_on_error: false, log_response_on_error: false],
          decoder: :atoms
      end

      err_log =
        capture_log([metadata: [:request_body, :body_string]], fn ->
          TestForErrorsDisabledLogsLocally.call("myquery", %{})
        end)

      assert err_log =~ "GraphQL: Bad Response error"
      assert not (err_log =~ "request_body=")
      assert not (err_log =~ "body_string=")
    end

    test "does not log request_body and body_string if respective options are explicitly disabled globally",
         %{
           bypass: bypass
         } do
      Bypass.expect_once(bypass, "POST", "/graphql", fn conn ->
        Plug.Conn.resp(conn, 500, "some 500 error")
      end)

      set_log_options_configuration(log_query?: false, log_response?: false)
      reload_app(_start_prima_auth0_ex? = false)
      on_exit(fn -> reload_app(_start_prima_auth0_ex? = false) end)

      defmodule TestForErrorsDisabledLogsGlobal do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          decoder: :atoms
      end

      err_log =
        capture_log([metadata: [:request_body, :body_string]], fn ->
          TestForErrorsDisabledLogsGlobal.call("myquery", %{})
        end)

      assert err_log =~ "GraphQL: Bad Response error"
      assert not (err_log =~ "request_body=")
      assert not (err_log =~ "body_string=")
    end
  end

  describe "when an HTTP error occurs" do
    test "by default, does not log request_body",
         %{
           bypass: bypass
         } do
      Bypass.down(bypass)

      defmodule TestForHTTPErrorNoLogs do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          decoder: :atoms
      end

      err_log =
        capture_log([metadata: [:request_body, :body_string]], fn ->
          TestForHTTPErrorNoLogs.call("myquery", %{})
        end)

      assert err_log =~ "GraphQL: HTTP error"
      assert not (err_log =~ "request_body=")

      Bypass.up(bypass)
    end

    test "logs request_body if option is enabled locally",
         %{
           bypass: bypass
         } do
      Bypass.down(bypass)

      defmodule TestForHTTPErrorWithLogsLocal do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          log_options: [log_query_on_error: true],
          decoder: :atoms
      end

      err_log =
        capture_log([metadata: [:request_body, :body_string]], fn ->
          TestForHTTPErrorWithLogsLocal.call("myquery", %{})
        end)

      assert err_log =~ "GraphQL: HTTP error"
      assert err_log =~ "request_body="

      Bypass.up(bypass)
    end

    test "logs request_body if option is enabled globally",
         %{
           bypass: bypass
         } do
      Bypass.down(bypass)

      set_log_options_configuration(log_query?: true)
      reload_app(_start_prima_auth0_ex? = false)
      on_exit(fn -> reload_app(_start_prima_auth0_ex? = false) end)

      defmodule TestForHTTPErrorWithLogsGlobal do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          decoder: :atoms
      end

      err_log =
        capture_log([metadata: [:request_body, :body_string]], fn ->
          TestForHTTPErrorWithLogsGlobal.call("myquery", %{})
        end)

      assert err_log =~ "GraphQL: HTTP error"
      assert err_log =~ "request_body="

      Bypass.up(bypass)
    end

    test "does not log request_body if option is explicitly disabled locally",
         %{
           bypass: bypass
         } do
      Bypass.down(bypass)

      defmodule TestForHTTPErrorDisabledLogsLocal do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          log_options: [log_query_on_error: false],
          decoder: :atoms
      end

      err_log =
        capture_log([metadata: [:request_body, :body_string]], fn ->
          TestForHTTPErrorDisabledLogsLocal.call("myquery", %{})
        end)

      assert err_log =~ "GraphQL: HTTP error"
      assert not (err_log =~ "request_body=")

      Bypass.up(bypass)
    end

    test "does not log request_body if option is explicitly disabled globally",
         %{
           bypass: bypass
         } do
      Bypass.down(bypass)

      set_log_options_configuration(log_query?: false)
      reload_app(_start_prima_auth0_ex? = false)
      on_exit(fn -> reload_app(_start_prima_auth0_ex? = false) end)

      defmodule TestForHTTPErrorDisabledLogsGlobal do
        use BridgeEx.Graphql,
          endpoint: "http://localhost:#{bypass.port}/graphql",
          decoder: :atoms
      end

      err_log =
        capture_log([metadata: [:request_body, :body_string]], fn ->
          TestForHTTPErrorDisabledLogsGlobal.call("myquery", %{})
        end)

      assert err_log =~ "GraphQL: HTTP error"
      assert not (err_log =~ "request_body=")

      Bypass.up(bypass)
    end
  end
end
