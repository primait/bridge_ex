defmodule BridgeEx.Graphql.RetryTest do
  use ExUnit.Case, async: true

  alias BridgeEx.Graphql.Retry
  alias BridgeEx.Utils.Counter

  setup do
    {:ok, counter} = Counter.start(0)
    on_exit(fn -> Counter.stop(counter) end)
    {:ok, counter: counter}
  end

  test "returns function result without retrying on success", %{counter: counter} do
    expected_result = {:ok, "Some result"}

    mock_function = fn _ ->
      Counter.increment(counter)
      expected_result
    end

    max_retries = 3

    result =
      Retry.retry(
        "Some argument",
        mock_function,
        &retry_always/1,
        max_retries
      )

    assert Counter.count(counter) == 1
    assert result == expected_result
  end

  test "retry a function on error until max retries", %{counter: counter} do
    mock_function = fn _ ->
      Counter.increment(counter)
      {:error, "Error"}
    end

    expected_retries = 3

    Retry.retry(
      "Some argument",
      mock_function,
      &retry_always/1,
      expected_retries
    )

    assert Counter.count(counter) == expected_retries
  end

  test "retry a function based on policy", %{counter: counter} do
    mock_function = fn _ ->
      Counter.increment(counter)
      {:error, "Error"}
    end

    max_retries = 3

    Retry.retry(
      "Some argument",
      mock_function,
      fn
        "Error" -> false
        _ -> true
      end,
      max_retries
    )

    assert Counter.count(counter) == 1
  end

  def retry_always(_), do: true
end
