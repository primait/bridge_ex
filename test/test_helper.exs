ExUnit.start()

defmodule BridgeEx.TestHelper do
  import ExUnit.Callbacks

  def set_test_env(app, key, new_value) do
    previous_value = Application.get_env(app, key, :unset)
    Application.put_env(app, key, new_value)

    on_exit(fn ->
      if previous_value == :unset,
        do: Application.delete_env(app, key),
        else: Application.put_env(app, key, previous_value)
    end)
  end

  def reload_app do
    Application.stop(:bridge_ex)
    Application.start(:bridge_ex)
  end

  def set_auth0_configuration(port, auth0_enabled? \\ true) do
    set_test_env(:bridge_ex, :auth0_enabled, auth0_enabled?)
    set_test_env(:prima_auth0_ex, :auth0_base_url, "http://localhost:#{port}")
    set_test_env(:prima_auth0_ex, :client, client_id: "", client_secret: "", cache_enabled: false)
  end

  def set_log_options_configuration(opts) do
    set_test_env(:bridge_ex, :log_options,
      log_query_on_error: Keyword.get(opts, :log_query?, false),
      log_response_on_error: Keyword.get(opts, :log_response?, false)
    )
  end
end
