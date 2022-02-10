defmodule BridgeEx.Graphql.UtilsTest do
  use ExUnit.Case, async: true

  alias BridgeEx.Graphql.Utils

  describe "normalize_inner_fields" do
    test "does not change strings" do
      assert "some-string" == Utils.normalize_inner_fields("some-string")
    end

    test "does not change empty maps" do
      assert %{} == Utils.normalize_inner_fields(%{})
    end

    test "does not change maps with snake case keys" do
      assert %{"some_key" => "value"} ==
               Utils.normalize_inner_fields(%{"some_key" => "value"})
    end

    test "transforms camel-case string keys to snake case" do
      assert %{"some_key" => "value"} ==
               Utils.normalize_inner_fields(%{"someKey" => "value"})
    end

    test "transforms camel-case atom keys to snake case" do
      assert %{some_key: "value"} ==
               Utils.normalize_inner_fields(%{someKey: "value"})
    end

    test "transforms inner keys" do
      assert %{"some_key" => %{"inner_key" => "value"}} ==
               Utils.normalize_inner_fields(%{"someKey" => %{"innerKey" => "value"}})
    end

    test "transforms keys in objects nested in arrays" do
      assert %{"some_key" => [%{"inner_key" => "value"}]} ==
               Utils.normalize_inner_fields(%{"someKey" => [%{"innerKey" => "value"}]})
    end
  end
end
