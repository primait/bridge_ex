defmodule BridgeEx.Graphql.Formatter.CamelCaseTest do
  use ExUnit.Case, async: true

  alias BridgeEx.Graphql.Formatter.CamelCase

  describe "format/1" do
    test "when argument is nil it should return nil" do
      assert CamelCase.format(nil) == nil
    end

    test "does not change strings" do
      assert "some-string" == CamelCase.format("some-string")
    end

    test "does not change integers" do
      assert 5 == CamelCase.format(5)
    end

    test "does not change booleans" do
      assert true == CamelCase.format(true)
    end

    test "does not change empty maps" do
      assert %{} == CamelCase.format(%{})
    end

    test "does not change maps with camel case keys" do
      assert %{"someKey" => "value"} ==
               CamelCase.format(%{"someKey" => "value"})
    end

    test "transforms snake-case string keys to camel case" do
      assert %{"someKey" => "value"} ==
               CamelCase.format(%{"some_key" => "value"})
    end

    test "transforms snake-case atom keys to camel case" do
      assert %{someKey: "value"} ==
               CamelCase.format(%{some_key: "value"})
    end

    test "transforms inner keys" do
      assert %{"someKey" => %{"innerKey" => "value"}} ==
               CamelCase.format(%{"some_key" => %{"inner_key" => "value"}})
    end

    test "transforms keys in objects nested in arrays" do
      assert %{"someKey" => [%{"innerKey" => "value"}]} ==
               CamelCase.format(%{"some_key" => [%{"inner_key" => "value"}]})
    end
  end
end
