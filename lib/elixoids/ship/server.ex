defmodule Elixoids.Ship.Server do
  @moduledoc """
  Space ship controlled by a player or bot over a websocker.
  Ships have position and size.
  Ships are identified by a unique integer.
  Players are identified by a 3-char string (AAA..ZZZ)
  Players control ships - the game maintains a map of Player to Ship
  """

  use GenServer

  alias Elixoids.Api.SoundEvent
  alias Elixoids.Game.Server, as: GameServer
  alias Elixoids.News
  alias Elixoids.Player
  alias Elixoids.Ship.Location, as: ShipLoc
  alias Elixoids.Space
  alias Elixoids.World.Point
  import Elixoids.News
  import Elixoids.World.Clock
  import Elixoids.World.Angle
  import Elixoids.Game.Identifiers

  use Elixoids.Game.Heartbeat

  # Ship radius (m)
  @ship_radius_m 20.0

  # The spawn point of a bullet
  @nose_radius_m @ship_radius_m * 1.05

  # Rotation rate (radians/sec). Three seconds to turn a complete circle.
  @ship_rotation_rad_per_sec :math.pi() * 2 / 3.0

  # Minimum time between shots
  @laser_recharge_ms 660
  @laser_recharge_penalty_ms @laser_recharge_ms * 2
  @max_shields 3

  def start_link(game_id, tag \\ Player.random_tag(), opts \\ %{}) do
    ship =
      random_ship()
      |> Map.merge(opts)
      |> Map.merge(%{
        :id => next_id(),
        :tag => tag,
        :game_id => game_id,
        :shields => @max_shields
      })

    ship_id = {game_id, tag}

    case GenServer.start_link(__MODULE__, ship, name: via(ship_id)) do
      {:ok, pid} -> {:ok, pid, ship_id}
      e -> e
    end
  end

  defp via(ship_id),
    do: {:via, Registry, {Registry.Elixoids.Ships, ship_id}}

  def new_heading(ship_id, theta), do: GenServer.cast(via(ship_id), {:new_heading, theta})

  def hyperspace(ship_id), do: GenServer.cast(via(ship_id), :hyperspace)

  def player_disconnect(ship_id), do: GenServer.cast(via(ship_id), :player_disconnect)

  def bullet_hit_ship(ship_pid, shooter_tag) when is_pid(ship_pid),
    do: GenServer.cast(ship_pid, {:bullet_hit_ship, shooter_tag})

  @doc """
  Player pulls trigger, which may fire a bullet
  if the ship is recharged.
  """
  def player_pulls_trigger(ship_id), do: GenServer.cast(via(ship_id), :player_pulls_trigger)

  def game_state_req(ship_id), do: GenServer.call(via(ship_id), :game_state_req)

  # GenServer callbacks

  def init(ship) do
    start_heartbeat()
    {:ok, ship}
  end

  @doc """
  Hyperspace the ship to a new position.
  """
  def handle_cast(:hyperspace, ship) do
    new_ship =
      %{ship | pos: random_ship_point(), theta: random_angle()}
      |> discharge_laser
      |> recharge_shields

    {:noreply, new_ship}
  end

  def handle_cast({:bullet_hit_ship, _shooter_tag}, ship = %{shields: shields})
      when shields > 0 do
    {:noreply, %{ship | shields: shields - 1}}
  end

  def handle_cast(
        {:bullet_hit_ship, shooter_tag},
        ship = %{pos: pos, radius: radius, game_id: game_id, tag: tag}
      ) do
    hyperspace(self())
    Elixoids.Game.Server.explosion(game_id, pos, radius)
    publish_news(game_id, [shooter_tag, "kills", tag])

    {:noreply, ship}
  end

  def handle_cast({:new_heading, theta}, ship) do
    if valid_theta?(theta) do
      {:noreply, %{ship | target_theta: normalize_radians(theta)}}
    else
      {:noreply, ship}
    end
  end

  def handle_cast(:player_pulls_trigger, ship) do
    if past?(ship.laser_charged_at) do
      fire_bullet(ship)
      {:noreply, recharge_laser(ship)}
    else
      {:noreply, ship}
    end
  end

  def handle_cast(:player_disconnect, ship), do: {:stop, :normal, ship}

  def handle_call(:game_state_req, from, ship = %{game_id: game_id}) do
    :ok = GameServer.state_of_ship(game_id, self(), from)
    {:noreply, ship}
  end

  defp fire_bullet(ship = %{game_id: game_id, pos: ship_centre, theta: theta}) do
    pos = Point.move(ship_centre, theta, @nose_radius_m)
    GameServer.bullet_fired(game_id, ship.tag, pos, theta)
    publish_news(game_id, [ship.tag, "fires"])
    e = pos.x |> Space.frac_x() |> SoundEvent.fire()
    News.publish_audio(game_id, e)
  end

  # Data

  defp state_tuple(ship) do
    %ShipLoc{
      pid: self(),
      id: ship.id,
      tag: ship.tag,
      pos: ship.pos,
      radius: ship.radius,
      theta: Float.round(ship.theta, 3)
    }
  end

  defp random_ship do
    %{
      :laser_charged_at => now_ms() - 1,
      :pos => random_ship_point(),
      :radius => @ship_radius_m,
      :theta => 0.0,
      :target_theta => 0.0
    }
  end

  def random_ship_point, do: Space.random_grid_point()

  defp clip_delta_theta(delta_theta, delta_t_ms) do
    max_theta = @ship_rotation_rad_per_sec * delta_t_ms / 1000.0

    if delta_theta > max_theta do
      max_theta
    else
      delta_theta
    end
  end

  @doc """
  Rotate the ship from it's current theta towards it's
  intended delta_theta - but clip the rate of rotation
  by the time elapsed since the last frame.
  """
  def rotate_ship(ship, delta_t_ms) do
    delta_theta = clip_delta_theta(abs(ship.target_theta - ship.theta), delta_t_ms)

    turn =
      if turn_positive?(ship.target_theta, ship.theta) do
        delta_theta
      else
        -delta_theta
      end

    theta = normalize_radians(ship.theta + turn)
    %{ship | :theta => theta}
  end

  @doc """
  Update game state with time at which they can fire again
  """
  def recharge_laser(ship) do
    %{ship | :laser_charged_at => now_ms() + @laser_recharge_ms}
  end

  def discharge_laser(ship) do
    %{ship | :laser_charged_at => now_ms() + @laser_recharge_penalty_ms}
  end

  defp recharge_shields(ship), do: %{ship | shields: @max_shields}

  def handle_tick(_pid, delta_t_ms, ship = %{game_id: game_id}) do
    new_ship = ship |> rotate_ship(delta_t_ms)

    GameServer.update_ship(game_id, state_tuple(new_ship))
    {:ok, new_ship}
  end
end
