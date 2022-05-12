defmodule BridgeEx.Extensions.ExternalResourcesTest do
  use ExUnit.Case

  defmodule Example do
    use BridgeEx.Extensions.ExternalResources,
      resources: [
        question: "resources/question.txt",
        answer: "resources/answer.txt"
      ]
  end

  test "it generates getter functions" do
    assert "How many roads must a man walk down?" == Example.question()
    assert "42" == Example.answer()
  end

  test "it marks files as external resources" do
    paths =
      for {:external_resource, [path]} <- Example.__info__(:attributes),
          into: MapSet.new(),
          do: Path.relative_to(path, __DIR__)

    assert MapSet.new(["resources/question.txt", "resources/answer.txt"]) == paths
  end

  test "it fails to compile if no resources are given" do
    quoted =
      quote do
        use BridgeEx.Extensions.ExternalResources
      end

    assert_raise FunctionClauseError, fn -> Code.eval_quoted(quoted) end
  end

  test "it fails to compile if a file is missing" do
    quoted =
      quote do
        use BridgeEx.Extensions.ExternalResources,
          resources: [
            missing: "missing.txt"
          ]
      end

    assert_raise File.Error, fn -> Code.eval_quoted(quoted) end
  end
end
