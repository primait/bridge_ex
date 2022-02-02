defmodule BridgeEx.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    if Application.get_env(:bridge_ex, :auth0_enabled) do
      {:ok, _} = Application.ensure_all_started(:prima_auth0_ex)
    end

    children = []
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
