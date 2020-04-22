defmodule Elixoids.Saucer.TargetTest do
  use ExUnit.Case

  alias Elixoids.Saucer.Server, as: Saucer

  @targets %Elixoids.Ship.Targets{
    origin: %Elixoids.World.Point{x: 4035.6, y: 1445.4728088279473},
    rocks: [
      %Elixoids.Asteroid.Location{
        id: 1637,
        pid: self(),
        pos: %Elixoids.World.Point{x: 4035.6300905691282, y: 1234.4738736282277},
        radius: 60.0
      },
      %Elixoids.Asteroid.Location{
        id: 1701,
        pid: self(),
        pos: %Elixoids.World.Point{x: 2186.7029960671, y: 57.79820348079595},
        radius: 120.0
      }
    ],
    ships: [
      %Elixoids.Ship.Location{
        id: {0, "MMQ"},
        pid: self(),
        pos: %Elixoids.World.Point{x: 577.2662498341853, y: 1836.8947862362095},
        radius: 20.0,
        tag: "MMQ",
        theta: 3.903
      },
      %Elixoids.Ship.Location{
        id: {0, "MFG"},
        pid: self(),
        pos: %Elixoids.World.Point{x: 2958.416527890292, y: 424.8557946764749},
        radius: 20.0,
        tag: "MFG",
        theta: 3.582
      },
      %Elixoids.Ship.Location{
        id: {0, "MIN"},
        pid: self(),
        pos: %Elixoids.World.Point{x: 3423.635624885272, y: 750.6536284010726},
        radius: 20.0,
        tag: "MIN",
        theta: 3.654
      }
    ],
    theta: 0.0
  }

  test "Target closest asteroid" do
    assert 3.99 == Saucer.select_target(@targets, 1000.0)
  end
end
