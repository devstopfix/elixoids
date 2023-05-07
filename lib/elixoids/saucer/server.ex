defmodule Elixoids.Saucer.Server do
  @moduledoc """
  Flying saucer NPC!

  This server is not restarted if the Saucer is destroyed.
  """

  use GenServer, restart: :transient
  use Elixoids.Game.Heartbeat

  alias Elixoids.Game.Server, as: GameServer
  alias Elixoids.Ship.Location, as: ShipLoc
  alias Elixoids.World.Point
  alias Elixoids.World.Velocity

  import Elixoids.Const, only: [asteroid_radius_m: 0, saucer_tag: 0]
  import Elixoids.News, only: [publish_news_fires: 2]
  import Elixoids.Ship.Rotate
  import Elixoids.Space, only: [random_point_on_vertical_edge: 0, wrap: 1]
  import Elixoids.Translate
  import Elixoids.World.Angle, only: [normalize_radians: 1]

  @tag saucer_tag()

  defmodule State do
    @moduledoc false
    @tag saucer_tag()
    defstruct accuracy: 0.025,
              direction_change_interval: nil,
              game_id: nil,
              id: nil,
              nose_radius_m: nil,
              pos: nil,
              radius: nil,
              rotation_rate_rad_per_sec: nil,
              saucer_radar_range: nil,
              shields: 0,
              shooting_interval: nil,
              speed_m_per_s: nil,
              tag: @tag,
              target_theta: 0,
              thetas: [],
              velocity: nil
  end

  def start_link(game_id: game_id, saucer: saucer) do
    id = {game_id, @tag}

    defaults = %{
      game_id: game_id,
      id: id,
      tag: @tag,
      nose_radius_m: saucer.radius * 1.05
    }

    state =
      random_saucer(saucer.speed_m_per_s)
      |> Map.merge(defaults)
      |> Map.merge(saucer)

    GenServer.start_link(__MODULE__, state, name: via(id))
  end

  defp via(ship_id),
    do: {:via, Registry, {Registry.Elixoids.Ships, ship_id}}

  @impl true
  def init(saucer) do
    GameServer.link(saucer.game_id, self())
    Process.flag(:trap_exit, true)
    start_heartbeat()
    send_change_direction_after(saucer.direction_change_interval)
    send_fire_after(saucer.shooting_interval)
    state = struct!(State, saucer)
    {:ok, state}
  end

  # Pick a new direction
  def handle_info(:change_direction, saucer) do
    send_change_direction_after(saucer.direction_change_interval)
    theta = Enum.random(saucer.thetas)
    {:noreply, %{saucer | target_theta: theta}}
  end

  # Pick a target and fire!
  def handle_info(:fire, %{game_id: game_id, tag: _tag} = saucer) do
    ref = make_ref()
    from = {self(), ref}
    :ok = GameServer.state_of_ship(game_id, self(), from)
    send_fire_after(saucer.shooting_interval)
    {:noreply, saucer}
  end

  def handle_info({_ref, %Elixoids.Ship.Targets{} = targets}, %{accuracy: accuracy} = saucer) do
    if theta = select_target(targets, saucer.saucer_radar_range) do
      bullet_theta = normalize_radians(theta + :rand.normal() * accuracy)
      bullet_pos = turret(bullet_theta, saucer)
      {:ok, _pid} = GameServer.bullet_fired(saucer.game_id, saucer.tag, bullet_pos, bullet_theta)
      # Do we need to know when bullet ends? If so
      # Process.link(pid)
      publish_news_fires(saucer.game_id, saucer.tag)
    end

    {:noreply, saucer}
  end

  # My bullet expired
  def handle_info({:EXIT, _, {:shutdown, :detonate}}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(:hyperspace, saucer) do
    explode(saucer)
    {:stop, {:shutdown, :crashed}, saucer}
  end

  def handle_cast({:bullet_hit_ship, _tag}, %{shields: shields} = saucer) when shields <= 0 do
    explode(saucer)
    {:stop, {:shutdown, :crashed}, saucer}
  end

  def handle_cast({:bullet_hit_ship, _tag}, %{shields: shields} = saucer) when shields > 0 do
    state = %{saucer | shields: shields - 1}
    {:noreply, state}
  end

  defp explode(saucer) do
    GameServer.explosion(saucer.game_id, saucer.pos, saucer.radius * 1.5)
  end

  @impl Elixoids.Game.Tick
  def handle_tick(_pid, delta_t_ms, saucer = %{game_id: game_id}) do
    pos =
      saucer.pos
      |> Velocity.apply_velocity(saucer.velocity, delta_t_ms)
      |> wrap()

    rotated_saucer = rotate_ship(saucer, delta_t_ms)

    next_saucer = %{rotated_saucer | pos: pos}

    ship_loc = %ShipLoc{
      pid: self(),
      id: saucer.id,
      tag: saucer.tag,
      pos: pos,
      radius: saucer.radius,
      theta: 0.0
    }

    GameServer.update_ship(game_id, ship_loc)
    {:ok, next_saucer}
  end

  @east [0, :math.pi() / 6.0, :math.pi() * 11 / 6.0]
  @west [:math.pi(), :math.pi() * 5 / 6.0, :math.pi() * 7 / 6.0]
  @directions [@east, @west]

  defp random_saucer(speed_m_per_s) do
    thetas = Enum.random(@directions)
    [theta | _] = thetas
    velocity = %Velocity{theta: theta, speed: speed_m_per_s}

    %{
      pos: random_point_on_vertical_edge(),
      target_theta: velocity.theta,
      thetas: thetas,
      velocity: velocity
    }
  end

  defp send_change_direction_after(time),
    do: Process.send_after(self(), :change_direction, time)

  defp send_fire_after(time),
    do: Process.send_after(self(), :fire, time)

  defp turret(theta, %{pos: ship_centre, nose_radius_m: radius}),
    do: Point.move(ship_centre, theta, radius)

  def select_target(%{origin: origin, rocks: rocks, ships: ships}, saucer_radar_range) do
    asteroids =
      rocks
      |> filter_large()
      |> asteroids_relative(origin)
      |> Enum.map(fn [_, t, r, d] -> [t: t, d: d, r: r] end)

    ships =
      ships
      |> ships_relative(origin)
      |> Enum.map(fn [_, t, d] -> [t: t, d: d, r: 20.0] end)

    candidates =
      (asteroids ++ ships)
      |> filter_radar(saucer_radar_range)
      |> sort_nearest()

    case List.first(candidates) do
      nil -> nil
      [t: t, d: _, r: _] -> t
    end
  end

  def filter_large(asteroids) do
    min_r = asteroid_radius_m()
    Enum.filter(asteroids, fn %{radius: r} -> r >= min_r end)
  end

  defp sort_nearest(targets) do
    Enum.sort(targets, fn [t: _, d: d1, r: _], [t: _, d: d2, r: _] -> d1 <= d2 end)
  end

  defp filter_radar(targets, max_r) do
    Enum.filter(targets, fn [t: _, d: d, r: _] -> d <= max_r end)
  end
end
