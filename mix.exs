defmodule BridgeEx.MixProject do
  use Mix.Project

  @source_url "https://github.com/primait/bridge_ex"
  @version "0.4.1"

  def project do
    [
      app: :bridge_ex,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      dialyzer: [plt_add_apps: [:prima_auth0_ex]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {BridgeEx.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:absinthe, "~> 1.6"},
      {:bypass, "~> 2.1", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.25.3", only: :dev, runtime: false},
      {:jason, "~> 1.2"},
      {:prima_auth0_ex, "~> 0.3.0", runtime: false},
      {:telepoison, "~> 1.0.0"}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  def package do
    [
      description: "BridgeEx is a library to build bridges to other services.",
      name: "bridge_ex",
      maintainers: ["Prima"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
