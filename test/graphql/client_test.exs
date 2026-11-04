defmodule BridgeEx.Graphql.ClientTest do
  use ExUnit.Case

  alias BridgeEx.Graphql.Client

  alias Bypass

  setup do
    bypass = Bypass.open(port: 55_000)
    {:ok, bypass: bypass}
  end

  test "call using deprecated atom keys decoder", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 200, ~s[{"data": {"result": "ok"}}])
    end)

    assert {:ok, %{result: "ok"}} = Client.call("localhost:55000/", "", %{}, decode_keys: :atoms)
  end

  test "call using safer string keys decoder", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 200, ~s[{"data": {"result": "ok"}}])
    end)

    assert {:ok, %{"result" => "ok"}} =
             Client.call("localhost:55000/", "", %{}, decode_keys: :strings)
  end

  test "call using new existing atom keys decoder", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 200, ~s[{"data": {"new_atom": "ok"}}])
    end)

    assert {:ok, %{new_atom: "ok"}} =
             Client.call("localhost:55000/", "", %{}, decode_keys: :existing_atoms)
  end

  test "content-type header is rejected", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/", fn conn ->
      content_type_header_count =
        Enum.count(conn.req_headers, fn {key, _value} ->
          String.downcase(to_string(key)) == "content-type"
        end)

      assert content_type_header_count == 1
      assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]
      Plug.Conn.resp(conn, 200, ~s[{"data": {"result": "ok"}}])
    end)

    headers = %{
      "Content-Type" => "text/html",
      "content-type" => "text/css",
      "Content-type" => "application/json"
    }

    _ = Client.call("localhost:55000/", "", %{}, headers: headers)
  end
end
