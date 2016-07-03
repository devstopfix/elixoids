defmodule Elixoids.Mixfile do
  use Mix.Project

  def project do
    [app: :elixoids,
     description: "Asteroids game server",
     name: "Elixoids",
     version: "0.8.2",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["J Every"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/devstopfix/elixoids"},
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:excheck, "~> 0.4", only: :test},
     {:triq, github: "krestenkrab/triq", only: :test},
     {:credo, "~> 0.3", only: [:dev, :test]},
     {:mix_test_watch, "~> 0.2", only: :dev}]
  end
  
end
