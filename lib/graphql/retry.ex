defmodule BridgeEx.Graphql.Retry do
  @moduledoc """
  Utils for handling retrying of functions.
  """

  @spec retry(
          String.t(),
          (any() -> {:error, String.t()} | {:ok, any()}),
          Keyword.t()
        ) :: {:ok, any()} | {:error, any()}
  def retry(arg, fun, retry_options) do
    delay = Keyword.fetch!(retry_options, :delay)
    policy = Keyword.fetch!(retry_options, :policy)
    timing = Keyword.fetch!(retry_options, :timing)
    max_retries = Keyword.fetch!(retry_options, :max_retries)

    do_retry(arg, fun, policy, delay, timing, max_retries + 1)
  end

  defp do_retry(arg, fun, _retry_policy, _delay, _timing, 1), do: fun.(arg)

  defp do_retry(_arg, _fun, _retry_policy, _delay, _timing, n) when n <= 0,
    do: {:error, :invalid_retry_value}

  defp do_retry(arg, fun, policy, delay, timing, retries) do
    case fun.(arg) do
      {:error, reason} ->
        if policy.(reason) do
          Process.sleep(calculate_new_delay(delay, timing))

          do_retry(arg, fun, policy, delay, timing, retries - 1)
        else
          {:error, reason}
        end

      val ->
        val
    end
  end

  defp calculate_new_delay(delay, :constant), do: delay

  defp calculate_new_delay(delay, :exponential) do
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
