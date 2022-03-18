defmodule BridgeEx.Graphql.Retry do
  @moduledoc """
  Misc utils for handling Graphql requests/responses.
  """

  @spec retry(
          {:ok, String.t()} | {:error, Jason.EncodeError.t() | Exception.t()},
          (any() -> {:error, String.t()} | {:ok, any()}),
          integer()
        ) :: {:ok, any()} | {:error, any()}
  def retry({:error, %Jason.EncodeError{message: message}}, _fun, _attempt) do
    {:error, message}
  end

  def retry({:ok, arg}, fun, _retry_policy, 1), do: fun.(arg)

  def retry({:ok, _arg}, _fun, _retry_policy, n) when n <= 0,
    do: {:error, :invalid_retry_value}

  def retry({:ok, arg}, fun, retry_policy, n) do
    do_retry(arg, fun, retry_policy, 500, n)
  end

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
