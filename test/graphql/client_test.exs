defmodule BridgeEx.Graphql.ClientTest do
  use ExUnit.Case

  alias BridgeEx.Graphql.Client
  alias BridgeEx.Graphql.Utils

  alias Bypass

  setup do
    bypass = Bypass.open(port: 55_000)
    {:ok, bypass: bypass}
  end

  test "call using deprecated atom decoder", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(%{data: %{result: "ok"}}))
    end)

    assert {:ok, %{result: "ok"}} = Client.call("localhost:55000/", "", %{}, [])
  end

  test "call using safer string decoder", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(%{data: %{result: "ok"}}))
    end)

    assert {:ok, %{"result" => "ok"}} =
             Client.call("localhost:55000/", "", %{}, &Utils.string_decoder/1, [])
  end

  test "call using new enforced atom decoder", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(%{data: %{"new_atom" => "ok"}}))
    end)

    assert {:ok, %{new_atom: "ok"}} =
             Client.call("localhost:55000/", "", %{}, &Utils.existing_atom_decoder/1, [])
  end
end
