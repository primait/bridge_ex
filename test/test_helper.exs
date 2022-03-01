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

  def reload_app(start_prima_auth0_ex?) do
    Application.stop(:bridge_ex)
    Application.start(:bridge_ex)

    if start_prima_auth0_ex? do
      {:ok, _} = Application.ensure_all_started(:prima_auth0_ex)
      on_exit(fn -> Application.stop(:prima_auth0_ex) end)
    end
  end

  def set_auth0_configuration(port) do
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
