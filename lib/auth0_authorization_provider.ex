defmodule BridgeEx.Auth0AuthorizationProvider do
  @moduledoc "Integration with Auth0 to authorize m2m communication"

  def authorization_headers(audience) do
    with {:ok, token} <- PrimaAuth0Ex.token_for(audience) do
      {:ok, %{"Authorization" => "Bearer #{token}"}}
    end
  end
end
