ExUnit.start(exclude: [:gnuplot, :large])
ExCheck.start()

Code.require_file("test/generators.exs")
