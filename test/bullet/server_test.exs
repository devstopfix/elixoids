defmodule Bullet.ServerTest do
  use ExUnit.Case, async: false
  doctest Bullet.Server

  alias Bullet.Server, as: Bullet

  test "Bullet live 2-3 seconds" do
    now = World.Clock.now_ms
    ttl = Bullet.calculate_ttl

    assert ttl > now

    elapsed_ms = (ttl - now)
    assert elapsed_ms <= (3 * 1000)
    assert elapsed_ms >= (2 * 1000)
  end

  test "UI state" do
    b = %{:pos=>%World.Point{:x=>1000.001,:y=>2000.06}, :id=>1}
    state = Bullet.state_tuple(b)
    assert {1, 1000.0, 2000.1} = state
  end

  test "Stop a bullet" do
      {:ok, b} = Bullet.start_link(999, 
                   %World.Point{:x=>0.0, :y=>0.0}, 
                   1.0,
                   0,
                   self())
      assert Process.alive?(b)

      #ref  = Process.monitor(b)
      #assert_received {:stop}, 500

      Bullet.stop(b)
      :timer.sleep(10)

      refute Process.alive?(b)
  end

end
