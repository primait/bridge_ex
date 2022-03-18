defmodule BridgeEx.Graphql.RetryTest do
  use ExUnit.Case, async: true

  alias BridgeEx.Graphql.Retry

  setup do
    {:ok, agent} = Agent.start(fn -> 0 end)
    on_exit(fn -> Agent.stop(agent) end)
    {:ok, agent: agent}
  end

  test "retry a function on error until max retries", %{agent: agent} do
    mock_function = fn _ ->
      Agent.update(agent, fn counter -> counter + 1 end)
      {:error, "Error"}
    end

    expected_retries = 3

    Retry.retry(
      {:ok, ""},
      mock_function,
      &retry_always/1,
      expected_retries
    )

    assert Agent.get(agent, fn counter -> counter end) == expected_retries
  end

  def retry_always(_), do: true
end
