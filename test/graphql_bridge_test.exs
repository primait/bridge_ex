defmodule GraphqlBridgeTest do
  use ExUnit.Case
  doctest GraphqlBridge

  test "greets the world" do
    assert GraphqlBridge.hello() == :world
  end
end
