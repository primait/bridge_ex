defmodule BridgeEx.Utils.Counter do
  @moduledoc false

  def start(initial_value) do
    Agent.start(fn -> initial_value end)
  end

  def stop(agent) do
    Agent.stop(agent)
  end

  def count(agent) do
    Agent.get(agent, & &1)
  end

  def increment(agent) do
    Agent.update(agent, &(&1 + 1))
  end
end
