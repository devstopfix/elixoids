defmodule Elixoids.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elixoids,
      description: "Asteroids Arcade Game Server",
      name: "Elixoids",
      version: "3.20.162",
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      dialyzer: [flags: [:error_handling, :underspecs]],
      elixirc_options: [warnings_as_errors: true]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["J Every"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/devstopfix/elixoids",
        "CI" => "https://travis-ci.org/devstopfix/elixoids",
        "Audio" => "https://github.com/jrothwell/sonic-asteroids/",
        "Graphics" => "https://github.com/lachok/asteroids"
      }
    ]
  end

  def application do
    [
      mod: {Elixoids.Application, []},
      extra_applications: [:cowboy, :ranch, :logger]
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 2.8"},
      {:credo, "~> 1.5", only: [:dev, :test]},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:gnuplot, "~> 1.19", only: :test},
      {:jason, "~> 1.2"},
      {:protobuf, "~> 0.7"},
      {:excheck, git: "https://github.com/devstopfix/excheck.git", tag: "0.7.6", only: :test},
      {:triq, "~> 1.3", only: [:dev, :test]}
    ]
  end
end
