ExUnit.start(exclude: [:gnuplot, :large, :fuzz, :bullet], timeout: 120_000)
ExCheck.start()

Code.require_file("test/generators.exs")
