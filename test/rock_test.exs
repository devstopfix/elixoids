defmodule Elixoids.RockTest do
  use ExUnit.Case, async: true
  doctest Asteroid.Server

  alias Elixoids.Asteroid.Rock
  alias Elixoids.World.Point
  alias Elixoids.World.Velocity

  test "Cleave asteroid in half" do
    rock = %Rock{pos: %Point{}, velocity: Velocity.east(10.0), radius: 100.0}

    assert [rock1, rock2] = Rock.cleave(rock, 2)

    assert 50.0 == rock1.radius
    assert 50.0 == rock2.radius

    assert rock1.velocity.theta > 0.78
    assert rock2.velocity.theta > 5.49

    assert 20.0 == rock1.velocity.speed
    assert 20.0 == rock2.velocity.speed

    assert rock1.pos.x > 10.0
    assert rock1.pos.y > 10.0
    assert rock2.pos.x > 10.0
    assert rock2.pos.y < -10.0
  end
end
