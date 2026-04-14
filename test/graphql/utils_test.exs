defmodule BridgeEx.Graphql.UtilsTest do
  use ExUnit.Case

  alias BridgeEx.Graphql.Utils

  describe "parse_operation_metadata/1" do
    test "extracts type and name from a named query" do
      assert {"query", "FindUser"} = Utils.parse_operation_metadata("query FindUser { user { id } }")
    end

    test "extracts type and name from a named mutation" do
      assert {"mutation", "CreateOrder"} =
               Utils.parse_operation_metadata("mutation CreateOrder($input: OrderInput!) { createOrder(input: $input) { id } }")
    end

    test "extracts type and name from a named subscription" do
      assert {"subscription", "OnOrderUpdated"} =
               Utils.parse_operation_metadata("subscription OnOrderUpdated { orderUpdated { id } }")
    end

    test "returns anonymous for a named-less query keyword" do
      assert {"query", "anonymous"} = Utils.parse_operation_metadata("query { user { id } }")
    end

    test "returns anonymous for a named-less mutation keyword" do
      assert {"mutation", "anonymous"} = Utils.parse_operation_metadata("mutation { createUser { id } }")
    end

    test "returns query/anonymous for shorthand query (no keyword)" do
      assert {"query", "anonymous"} = Utils.parse_operation_metadata("{ user { id } }")
    end

    test "handles leading whitespace and newlines" do
      assert {"query", "FindUser"} =
               Utils.parse_operation_metadata("\n  query FindUser { user { id } }")
    end
  end
end
