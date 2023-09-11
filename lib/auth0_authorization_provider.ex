defmodule BridgeEx.Auth0AuthorizationProvider do
  @moduledoc "Integration with Auth0 to authorize m2m communication"

  def authorization_headers(audience, nil) do
    with {:ok, token} <- PrimaAuth0Ex.token_for(audience) do
      {:ok, %{"Authorization" => "Bearer #{token}"}}
    end
  end

  def authorization_headers(audience, client) do
    with {:ok, token} <- PrimaAuth0Ex.token_for(audience, client) do
      {:ok, %{"Authorization" => "Bearer #{token}"}}
    end
  end
end
