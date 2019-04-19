defmodule Elixoids.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elixoids,
      description: "Asteroids Arcade Game Server",
      name: "Elixoids",
      version: "3.19.113",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
      # dialyzer: [flags: ["-Wunmatched_returns", :error_handling, :underspecs]]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["J Every"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/devstopfix/elixoids"}
    ]
  end

  def application do
    [mod: {Elixoids.Application, []}, extra_applications: [:cowboy, :ranch, :logger]]
  end

  defp deps do
    [
      {:cowboy, "~> 2.6"},
      {:credo, "~> 1.0.4", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:excheck, "~> 0.5.3", only: :test},
      {:jason, "~> 1.1"},
      {:mix_test_watch, "~> 0.9", only: :dev},
      {:triq, "~> 1.3", only: [:dev, :test]}
    ]
  end
end
