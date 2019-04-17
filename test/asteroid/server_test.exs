defmodule Asteroid.ServerTest do
  use ExUnit.Case, async: true
  doctest Asteroid.Server

  alias Asteroid.Server, as: Asteroid

  test "Cleave asteroid" do
    init = %{pos: %World.Point{}, velocity: World.Velocity.north(10.0), radius: 100.0}
    {:ok, a} = Asteroid.start_link(self(), init)

    [f1, f2] = Asteroid.split(a)

    assert f1.radius == 50.0
    assert f2.radius == 50.0

    refute Map.has_key?(f1, :id)
    refute Map.has_key?(f2, :id)

    assert f1.velocity.speed == 20.0
    assert f2.velocity.speed == 20.0

    assert f1.velocity.theta >= 1.856194490192345
    assert f2.velocity.theta <= 1.6
  end
end
