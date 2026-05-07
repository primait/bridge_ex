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

  defmodule ExampleWithIncludes do
    use BridgeEx.Extensions.ExternalResources,
      resources: [
        question: "resources/question.txt",
        answer: "resources/answer.txt"
      ],
      includes: ["resources/header.txt", "resources/extra.txt"]
  end

  test "it prepends included files" do
    assert "header content\nextra content\nHow many roads must a man walk down?" ==
             ExampleWithIncludes.question()
  end

  test "it fails to compile if an include file is missing" do
    quoted =
      quote do
        defmodule MissingInclude do
          use BridgeEx.Extensions.ExternalResources,
            resources: [question: "resources/question.txt"],
            includes: ["resources/non_existent.txt"]
        end
      end

    assert_raise File.Error, fn -> Code.eval_quoted(quoted) end
  end

  test "it fails to compile if includes is not a list" do
    quoted =
      quote do
        defmodule BadIncludes do
          use BridgeEx.Extensions.ExternalResources,
            resources: [question: "resources/question.txt"],
            includes: :bad_includes
        end
      end

    assert_raise ArgumentError, fn -> Code.eval_quoted(quoted) end
  end

  test "it fails to compile if no resources are given" do
    quoted =
      quote do
        defmodule NoResources do
          use BridgeEx.Extensions.ExternalResources
        end
      end

    assert_raise ArgumentError, fn -> Code.eval_quoted(quoted) end
  end

  test "it fails to compile if a file is missing" do
    quoted =
      quote do
        defmodule MissingFile do
          use BridgeEx.Extensions.ExternalResources,
            resources: [missing: "missing.txt"]
        end
      end

    assert_raise File.Error, fn -> Code.eval_quoted(quoted) end
  end

  test "it fails to compile if resources is not a list" do
    quoted =
      quote do
        defmodule BadResources do
          use BridgeEx.Extensions.ExternalResources,
            resources: :bad_res
        end
      end

    assert_raise ArgumentError, fn -> Code.eval_quoted(quoted) end
  end

  test "it fails to compile when an unknown option is passed" do
    quoted =
      quote do
        defmodule BadOpt do
          use BridgeEx.Extensions.ExternalResources,
            bad_opt: []
        end
      end

    assert_raise ArgumentError, fn -> Code.eval_quoted(quoted) end
  end

  test "it fails to compile if resources contains a bad entry" do
    quoted =
      quote do
        defmodule BadEntry do
          use BridgeEx.Extensions.ExternalResources,
            resources: [:bad_entry]
        end
      end

    assert_raise FunctionClauseError, fn -> Code.eval_quoted(quoted) end
  end

  test "it fails to compile if not called inside a module" do
    quoted =
      quote do
        use BridgeEx.Extensions.ExternalResources,
          resources: [question: "resources/question.txt"]
      end

    assert_raise ArgumentError, fn -> Code.eval_quoted(quoted) end
  end
end
