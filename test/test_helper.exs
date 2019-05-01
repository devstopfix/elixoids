ExUnit.start(exclude: [:gnuplot, :large, :slow])
ExCheck.start()

Code.require_file("test/generators.exs")
