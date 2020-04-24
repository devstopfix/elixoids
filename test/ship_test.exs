defmodule Elixoids.Ship.ServerTest do
  use ExUnit.Case, async: true
  use ExCheck

  import Elixoids.Ship.Rotate
  import Elixoids.Test.Generators, only: [gen_theta: 0]

  test "ship pointing east does not rotate" do
    ship = %{theta: 0.0, target_theta: 0.0, rotation_rate: :math.pi()}
    rotated_ship = rotate_ship(ship, 1 * 1000)
    assert 0.0 == rotated_ship[:theta]
  end

  test "rotate ship from East to North" do
    ship = %{theta: 0.0, target_theta: 1.2, rotation_rate: :math.pi()}
    rotated_ship = rotate_ship(ship, 1 * 1000)
    assert 1.2 == rotated_ship[:theta]
  end

  property :ships_pointing_desired_heading_do_not_rotate do
    for_all theta in gen_theta() do
      ship = %{theta: theta, target_theta: theta, rotation_rate: :math.pi()}
      rotated_ship = rotate_ship(ship, 100)
      assert theta == rotated_ship.theta
    end
  end

  @two_seconds 2 * 1_000

  property :ships_can_rotate_anticlockwise do
    for_all {theta} in such_that({t} in {gen_theta()} when t <= 5.2) do
      ship = %{theta: theta * 1.0, target_theta: theta + 1.0, rotation_rate: :math.pi()}
      rotated_ship = rotate_ship(ship, @two_seconds)
      assert rotated_ship.theta == ship.target_theta
    end
  end

  property :ships_can_rotate_clockwise do
    for_all {theta} in such_that({t} in {gen_theta()} when t > 1.0) do
      ship = %{theta: theta * 1.0, target_theta: theta - 1.0, rotation_rate: :math.pi()}
      rotated_ship = rotate_ship(ship, @two_seconds)
      assert rotated_ship.theta == ship.target_theta
    end
  end

  # Test that we can rotate from any starting angle to any finishing angle in a half-circle
  # within the maximum turn duration of a Ship (3 seconds)
  property :rotate_ship_half_turn do
    three_seconds = 3 * 1000

    for_all {theta, target_theta} in {int(0, 3), int(0, 3)} do
      ship = %{theta: theta, target_theta: target_theta, rotation_rate: :math.pi()}
      rotated_ship = rotate_ship(ship, three_seconds)
      assert rotated_ship.theta == target_theta
    end
  end

  # TODO add test for full rotation!

  # # Test that any rotation within a single frame takes the shortest path
  # property :rotate_ship_takes_shortest_path do
  #   for_all {theta, target_theta} in {int(0,6), int(0,6)} do
  #     ship = %{theta: theta*1.0, target_theta: target_theta*1.0}

  #     rotated_ship = Ship.rotate_ship(ship, 16)

  #     original_delta = abs(theta-target_theta)
  #     final_delta = abs(rotated_ship.theta-target_theta)

  #     assert final_delta <= original_delta
  #   end
  # end
end
