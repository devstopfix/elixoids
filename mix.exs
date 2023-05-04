defmodule Elixoids.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elixoids,
      description: "Asteroids Arcade Game Server",
      name: "Elixoids",
      version: "3.23.71",
      elixir: "~> 1.13",
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
      {:cowboy, "~> 2.10"},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:gnuplot, "~> 1.22", only: :test},
      {:jason, "~> 1.3"},
      {:protobuf, "~> 0.10"},
      {:excheck, git: "https://github.com/devstopfix/excheck.git", tag: "0.7.6", only: :test},
      {:triq, "~> 1.3", only: [:dev, :test]}
    ]
  end
end
