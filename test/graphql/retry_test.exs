defmodule BridgeEx.Graphql.RetryTest do
  use ExUnit.Case, async: true

  alias BridgeEx.Graphql.Retry
  alias BridgeEx.Utils.Counter

  setup do
    {:ok, counter} = Counter.start(0)
    on_exit(fn -> Counter.stop(counter) end)
    {:ok, counter: counter}
  end

  test "retry a function on error until max retries", %{counter: counter} do
    mock_function = fn _ ->
      Counter.increment(counter)
      {:error, "Error"}
    end

    expected_retries = 3

    Retry.retry(
      {:ok, ""},
      mock_function,
      &retry_always/1,
      expected_retries
    )

    assert Counter.count(counter) == expected_retries
  end

  def retry_always(_), do: true
end
