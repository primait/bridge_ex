defmodule BridgeEx.Graphql.Retry do
  @moduledoc """
  Misc utils for handling Graphql requests/responses.
  """

  @spec retry(
          String.t(),
          (any() -> {:error, String.t()} | {:ok, any()}),
          (any() -> boolean()),
          integer()
        ) :: {:ok, any()} | {:error, any()}
  def retry(arg, fun, retry_policy, n) do
    do_retry(arg, fun, retry_policy, 500, n)
  end

  defp do_retry(arg, fun, _retry_policy, _delay, 1), do: fun.(arg)

  defp do_retry(_arg, _fun, _retry_policy, _delay, n) when n <= 0,
    do: {:error, :invalid_retry_value}

  defp do_retry(arg, fun, policy, delay, retries) do
    case fun.(arg) do
      {:error, reason} ->
        if policy.(reason) do
          Process.sleep(delay)
          do_retry(arg, fun, policy, calculate_new_delay(delay), retries - 1)
        else
          {:error, reason}
        end

      val ->
        val
    end
  end

  defp calculate_new_delay(delay) do
    delay = delay * 2
    max_delta = round(delay * 0.1)
    shift = random_uniform(2 * max_delta) - max_delta

    case delay + shift do
      n when n <= 0 -> 0
      n -> n
    end
  end

  defp random_uniform(n) when n <= 0, do: 0

  defp random_uniform(n), do: :rand.uniform(n)
end
