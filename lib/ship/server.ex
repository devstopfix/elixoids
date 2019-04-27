defmodule Ship.Server do
  @moduledoc """
  Space ship controlled by a player or bot over a websocker.
  Ships have position and size.
  Ships are identified by a unique integer.
  Players are identified by a 3-char string (AAA..ZZZ)
  Players control ships - the game maintains a map of Player to Ship
  """

  use GenServer

  alias Elixoids.Api.SoundEvent
  alias Elixoids.Player
  alias Elixoids.Ship.Location, as: ShipLoc
  alias Elixoids.Space
  alias Elixoids.World.Velocity
  alias Game.Server, as: GameServer
  alias World.Clock
  import Elixoids.News
  import Game.Identifiers
  import Elixoids.World.Angle

  use Elixoids.Game.Heartbeat

  # Ship radius (m)
  @ship_radius_m 20.0

  # The spawn point of a bullet
  @nose_radius_m @ship_radius_m * 1.1

  # Rotation rate (radians/sec). Three seconds to turn a complete circle.
  @ship_rotation_rad_per_sec :math.pi() * 2 / 3.0

  # Minimum time between shots
  @laser_recharge_ms 660
  @laser_recharge_penalty_ms @laser_recharge_ms * 2

  def start_link(game_info, tag \\ Player.random_tag()) do
    ship =
      Map.merge(random_ship(), %{
        :id => next_id(),
        :tag => tag,
        :game => game_info
      })

    ship_id = {game_info.id, tag}

    case GenServer.start_link(__MODULE__, ship, name: via(ship_id)) do
      {:ok, pid} -> {:ok, pid, ship_id}
      e -> e
    end
  end

  defp via(ship_id),
    do: {:via, Registry, {Registry.Elixoids.Ships, ship_id}}

  @doc """
  Player requests turn to given theta.
  """
  def new_heading(ship_id, theta), do: GenServer.cast(via(ship_id), {:new_heading, theta})

  @doc """
  Move the ship to a random position on the map
  and prevent it firing.
  """
  def hyperspace(ship_pid) when is_pid(ship_pid), do: GenServer.cast(ship_pid, :hyperspace)

  def hyperspace(ship_id), do: GenServer.cast(via(ship_id), :hyperspace)

  @doc """
  Remove the ship from the game.
  """
  def stop(ship_id) do
    case Registry.lookup(Registry.Elixoids.Ships, ship_id) do
      [{pid, _} | _] -> Process.exit(pid, :shutdown)
      _ -> false
    end
  end

  @doc """
  Player pulls trigger, which may fire a bullet
  if the ship is recharged.
  """
  def player_pulls_trigger(ship_id), do: GenServer.cast(via(ship_id), :player_pulls_trigger)

  def game_state(ship_id), do: GenServer.call(via(ship_id), :game_state)

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

    {:noreply, new_ship}
  end

  def handle_cast({:new_heading, theta}, ship) do
    if valid_theta?(theta) do
      {:noreply, %{ship | target_theta: normalize_radians(theta)}}
    else
      {:noreply, ship}
    end
  end

  def handle_cast(:player_pulls_trigger, ship) do
    if Clock.past?(ship.laser_charged_at) do
      fire_bullet(ship)
      {:noreply, recharge_laser(ship)}
    else
      {:noreply, ship}
    end
  end

  def handle_call(:game_state, _from, ship = %{game: %{id: game_id}}) do
    {:reply, Game.Server.state_of_ship(game_id, self()), ship}
  end

  defp fire_bullet(ship) do
    pos = calculate_nose(ship)
    GameServer.bullet_fired(ship.game.id, ship.tag, pos, ship.theta)
    publish_news(ship.game.id, [ship.tag, "fires"])
    pan = Space.frac_x(ship.pos.x)
    Elixoids.News.publish_audio(ship.game.id, SoundEvent.fire(pan, ship.game.time.()))
  end

  defp calculate_nose(%{pos: ship_centre, theta: theta}) do
    v = %Velocity{:theta => theta, :speed => @nose_radius_m}
    Velocity.apply_velocity(ship_centre, v, 1000.0)
  end

  # Data

  defp state_tuple(ship) do
    %ShipLoc{
      pid: self(),
      id: ship.id,
      tag: ship.tag,
      pos: ship.pos,
      radius: @ship_radius_m,
      # TODO protocol?
      theta: Float.round(ship.theta, 3)
    }
  end

  defp random_ship do
    %{
      :pos => random_ship_point(),
      :theta => 0.0,
      :target_theta => 0.0,
      :laser_charged_at => Clock.now_ms() - 1
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
    %{ship | :laser_charged_at => Clock.now_ms() + @laser_recharge_ms}
  end

  def discharge_laser(ship) do
    %{ship | :laser_charged_at => Clock.now_ms() + @laser_recharge_penalty_ms}
  end

  # defimpl Elixoids.Game.Heartbeat.Tick do
  def handle_tick(_pid, delta_t_ms, ship) do
    new_ship = ship |> rotate_ship(delta_t_ms)

    GameServer.update_ship(ship.game.id, state_tuple(new_ship))
    {:ok, new_ship}
  end
end
