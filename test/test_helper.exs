ExUnit.start(exclude: [:gnuplot, :large, :fuzz, :slow])
ExCheck.start()

Code.require_file("test/generators.exs")
