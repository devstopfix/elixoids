defmodule Elixoids.Mixfile do
  use Mix.Project

  def project do
    [app: :elixoids,
     description: "Asteroids game and server",
     name: "Elixoids",
     version: "2.3.0",
     elixir: "~> 1.3.2",
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
    [ mod: { Elixoids.Server, [] },
      applications: [:cowboy, :ranch, :logger] ]
  end

  defp deps do
    [
     {:excheck, "~> 0.5", only: :test},
     {:triq, github: "triqng/triq", only: :test},
     
     {:credo, "~> 0.5", only: [:dev, :test]},
     {:mix_test_watch, "~> 0.2", only: :dev},
     {:cowboy, "1.0.4" },
     {:poison, "~> 3.0"},
     {:erlquad, path: "../erlquad"},
     {:csvlixir, "~> 2.0.3"}] # TODO remove
  end

end
