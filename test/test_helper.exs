ExUnit.start(exclude: [:gnuplot, :large, :fuzz])
ExCheck.start()

Code.require_file("test/generators.exs")
