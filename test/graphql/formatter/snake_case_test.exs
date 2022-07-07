defmodule BridgeEx.Graphql.Formatter.SnakeCaseTest do
  use ExUnit.Case, async: true

  alias BridgeEx.Graphql.Formatter.SnakeCase

  describe "format/1" do
    test "when argument is nil it should return nil" do
      assert SnakeCase.format(nil) == nil
    end

    test "does not change strings" do
      assert "some-string" == SnakeCase.format("some-string")
    end

    test "does not change integers" do
      assert 5 == SnakeCase.format(5)
    end

    test "does not change booleans" do
      assert true == SnakeCase.format(true)
    end

    test "does not change empty maps" do
      assert %{} == SnakeCase.format(%{})
    end

    test "does not change maps with snake case keys" do
      assert %{"some_key" => "value"} ==
               SnakeCase.format(%{"some_key" => "value"})
    end

    test "transforms camel-case string keys to snake case" do
      assert %{"some_key" => "value"} ==
               SnakeCase.format(%{"someKey" => "value"})
    end

    test "transforms camel-case atom keys to snake case" do
      assert %{some_key: "value"} ==
               SnakeCase.format(%{someKey: "value"})
    end

    test "transforms inner keys" do
      assert %{"some_key" => %{"inner_key" => "value"}} ==
               SnakeCase.format(%{"someKey" => %{"innerKey" => "value"}})
    end

    test "transforms keys in objects nested in arrays" do
      assert %{"some_key" => [%{"inner_key" => "value"}]} ==
               SnakeCase.format(%{"someKey" => [%{"innerKey" => "value"}]})
    end
  end
end
