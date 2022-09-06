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
end
