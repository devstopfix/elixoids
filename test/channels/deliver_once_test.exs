defmodule Channels.DeliverOnceTest do
  use ExUnit.Case, async: true
  doctest Channels.DeliverOnce

  alias Channels.DeliverOnce, as: DeliverOnce

  @empty_set MapSet.new()

  test "Empty channel" do
    assert {[], @empty_set} == DeliverOnce.deduplicate([], @empty_set)
  end

  test "Empty channel clears history" do
    assert {[], @empty_set} == DeliverOnce.deduplicate([], MapSet.new([1, 2, 3]))
  end

  test "New item is transmitted and remembered" do
    assert {[1], MapSet.new([1])} == DeliverOnce.deduplicate([1], @empty_set)
  end

  test "New items are transmitted and remembered, and appended to seen" do
    assert {[2], MapSet.new([1, 2])} == DeliverOnce.deduplicate([2], MapSet.new([1]))
  end
end
