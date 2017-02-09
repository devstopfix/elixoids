defmodule Game.IdentifiersTest do
  use ExUnit.Case, async: false
  use ExCheck
  doctest Game.Identifiers

  alias Game.Identifiers, as: Identifiers

  # Make an id generator, get a sequence of numbers, ensure consecutive
  property :generate_n_identifiers do
    for_all {n} in {pos_integer()} do

      {:ok, pid} = Identifiers.start_link

      ids = Enum.reduce(Range.new(1, n), [], 
        fn (_i, acc) -> [Identifiers.next(pid) | acc] end)

      assert ids == expected(n)
      assert List.first(ids) == n
      assert List.last(ids) == 1
    end
  end

  def expected(n) do
    Range.new(1, n) |> Enum.to_list |> Enum.reverse
  end

end
