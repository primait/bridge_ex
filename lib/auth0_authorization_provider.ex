defmodule BridgeEx.Auth0AuthorizationProvider do
  def authorization_headers(audience) do
    with {:ok, token} <- Auth0Ex.token_for(audience) do
      {:ok, %{"Authorization" => "Bearer #{token}"}}
    end
  end
end
