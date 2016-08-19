defmodule World.ClockTest do
  use ExUnit.Case, async: true
  doctest World.Clock

  alias World.Clock, as: Clock

  @t_past 1471605231831

  test "Now is after this test was written" do
    t = Clock.now_ms
    assert t > @t_past
  end

  test "Now is not in the past" do
    t = Clock.now_ms
    refute Clock.past?(t)
  end

  test "Future is not in the past" do
    t = Clock.now_ms + 1
    refute Clock.past?(t)
  end

  test "Sleep and test past?" do
    t = Clock.now_ms
    refute Clock.past?(t)
    :timer.sleep(1)
    assert Clock.past?(t)
  end

end
