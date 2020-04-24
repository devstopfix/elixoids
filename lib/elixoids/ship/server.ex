defmodule Elixoids.Ship.Server do
  @moduledoc """
  Space ship controlled by a player or bot over a websocker.
  Ships have position and size.
  Ships are identified by a unique integer.
  Players are identified by a 3-char string (AAA..ZZZ)
  Players control ships - the game maintains a map of Player to Ship
  """

  use GenServer

  alias Elixoids.Game.Server, as: GameServer
  alias Elixoids.Ship.Location, as: ShipLoc
  alias Elixoids.Space
  alias Elixoids.World.Point
  import Elixoids.Const
  import Elixoids.News
  import Elixoids.Ship.Shot
  import Elixoids.Ship.Rotate
  import Elixoids.World.Clock
  import Elixoids.World.Angle

  use Elixoids.Game.Heartbeat

  @max_inflight_bullets max_inflight_bullets()

  def start_link(game_id, tag, opts \\ %{}) do
    ship_id = {game_id, tag}

    ship =
      random_ship()
      |> Map.merge(opts)
      |> Map.merge(%{
        :id => ship_id,
        :tag => tag,
        :game_id => game_id,
        :shields => max_shields(),
        :bullets_in_flight => 0,
        :rotation_rate => ship_rotation_rate_rad_per_sec()
      })

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

  def bullet_hit_ship(ship_id, shooter_tag),
    do: GenServer.cast(via(ship_id), {:bullet_hit_ship, shooter_tag})

  @doc """
  Player pulls trigger, which may fire a bullet
  if the ship is recharged.
  """
  def player_pulls_trigger(ship_id), do: GenServer.cast(via(ship_id), :player_pulls_trigger)

  def game_state_req(ship_id), do: GenServer.call(via(ship_id), :game_state_req)

  # GenServer callbacks

  @impl true
  def init(ship) do
    start_heartbeat()
    Process.flag(:trap_exit, true)
    {:ok, ship}
  end

  @doc """
  Hyperspace the ship to a new position.
  """
  @impl true

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
        ship = %{pos: pos, radius: radius, game_id: game_id, tag: tag, id: ship_id}
      ) do
    hyperspace(ship_id)
    GameServer.explosion(game_id, pos, radius)
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

  def handle_cast(:player_pulls_trigger, %{bullets_in_flight: bullets_in_flight} = state)
      when bullets_in_flight >= @max_inflight_bullets do
    {:noreply, state}
  end

  def handle_cast(
        :player_pulls_trigger,
        %{game_id: game_id, tag: tag} = ship
      ) do
    if past?(ship.laser_charged_at) do
      state =
        ship
        |> fire()
        |> fire_sound()
        |> recharge_laser()
        |> inc_bullets()

      publish_news_fires(game_id, tag)

      {:noreply, state}
    else
      {:noreply, ship}
    end
  end

  def handle_cast(:player_disconnect, ship), do: {:stop, :normal, ship}

  @impl true
  def handle_call(:game_state_req, from, ship = %{game_id: game_id}) do
    :ok = GameServer.state_of_ship(game_id, self(), from)
    {:noreply, ship}
  end

  def handle_info({:EXIT, _, {:shutdown, :detonate}}, state) do
    {:noreply, dec_bullets(state)}
  end

  defp fire(%{game_id: game_id, tag: tag, theta: theta} = ship) do
    pos = turret(ship)
    {:ok, pid} = GameServer.bullet_fired(game_id, tag, pos, theta)
    Process.link(pid)
    ship
  end

  defp turret(%{pos: ship_centre, theta: theta}) do
    Point.move(ship_centre, theta, nose_radius_m())
  end

  # Data

  defp state_tuple(ship) do
    %ShipLoc{
      pid: self(),
      id: ship.id,
      tag: ship.tag,
      pos: ship.pos,
      radius: ship.radius,
      theta: Float.floor(ship.theta, 3)
    }
  end

  defp random_ship do
    %{
      :laser_charged_at => now_ms() - 1,
      :pos => random_ship_point(),
      :radius => ship_radius_m(),
      :theta => 0.0,
      :target_theta => 0.0
    }
  end

  def random_ship_point, do: Space.random_grid_point()

  @doc """
  Update game state with time at which they can fire again
  """
  def recharge_laser(ship) do
    %{ship | :laser_charged_at => now_ms() + laser_recharge_ms()}
  end

  def discharge_laser(ship) do
    %{ship | :laser_charged_at => now_ms() + laser_recharge_penalty_ms()}
  end

  defp recharge_shields(ship), do: %{ship | shields: max_shields()}

  defp inc_bullets(ship), do: Map.update!(ship, :bullets_in_flight, &(&1 + 1))

  defp dec_bullets(ship), do: Map.update!(ship, :bullets_in_flight, &max(&1 - 1, 0))

  @impl Elixoids.Game.Tick
  def handle_tick(_pid, delta_t_ms, ship = %{game_id: game_id}) do
    new_ship = ship |> rotate_ship(delta_t_ms)
    ship_state = state_tuple(new_ship)
    GameServer.update_ship(game_id, ship_state)
    {:ok, new_ship}
  end
end
