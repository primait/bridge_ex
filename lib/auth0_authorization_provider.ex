defmodule BridgeEx.Auth0AuthorizationProvider do
  @moduledoc "Integration with Auth0 to authorize m2m communication"

  require Logger

  def authorization_headers(audience) do
    if auth0_enabled_for_app(),
      do: retrieve_authorization_headers(audience),
      else: report_auth0_disabled_error()
  end

  defp retrieve_authorization_headers(audience) do
    with {:ok, token} <- PrimaAuth0Ex.token_for(audience) do
      {:ok, %{"Authorization" => "Bearer #{token}"}}
    end
  end

  defp report_auth0_disabled_error do
    Logger.error("Auth0 is not enabled for this application!
        Set it with `config :bridge_ex, auth0_enabled: true`")

    {:error, "Auth0 not enabled in application"}
  end

  defp auth0_enabled_for_app, do: Application.get_env(:bridge_ex, :auth0_enabled, false)
end
