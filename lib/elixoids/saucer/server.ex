defmodule Elixoids.Saucer.Server do
  @moduledoc """
  Flying saucer NPC!

  This server is not restarted if the Saucer is destroyed.

  The accuracy is a random normal value applied to the true bearing from saucer to target.

  * 0.0 -> 1.000
  * 0.05 -> 0.700
  * 0.1 -> 0.400
  """

  use GenServer, restart: :transient
  use Elixoids.Game.Heartbeat

  alias Elixoids.Game.Server, as: GameServer
  alias Elixoids.Ship.Location, as: ShipLoc
  alias Elixoids.World.Point
  alias Elixoids.World.Velocity

  import Elixoids.Const,
    only: [
      asteroid_radius_m: 0,
      saucer_speed_m_per_s: 0,
      saucer_direction_change_interval: 0,
      saucer_radar_range: 0,
      saucer_radius_large: 0,
      saucer_shooting_interval: 0,
      saucer_tag: 0
    ]

  import Elixoids.News, only: [publish_news_fires: 2]

  import Elixoids.Space, only: [random_point_on_vertical_edge: 0, wrap: 1]
  import Elixoids.Translate

  import Elixoids.World.Angle, only: [normalize_radians: 1]

  @pi34 :math.pi() * 3 / 4.0
  @pi54 :math.pi() * 5 / 4.0
  @angles [@pi34, @pi34, :math.pi(), @pi54, @pi54]
  @saucer_direction_change_interval saucer_direction_change_interval()
  @tag saucer_tag()

  def start_link(game_id) do
    id = {game_id, @tag}

    saucer =
      random_saucer()
      |> Map.merge(%{
        game_id: game_id,
        tag: @tag,
        thetas: Enum.map(@angles, &normalize_radians/1),
        id: id,
        accuracy: 0.05
      })

    GenServer.start_link(__MODULE__, saucer, name: via(id))
  end

  defp via(ship_id),
    do: {:via, Registry, {Registry.Elixoids.Ships, ship_id}}

  @impl true
  def init(saucer) do
    GameServer.link(saucer.game_id, self())
    Process.flag(:trap_exit, true)
    start_heartbeat()
    send_change_direction_after()
    send_fire_after()
    {:ok, saucer}
  end

  def handle_info(:change_direction, saucer) do
    send_change_direction_after()
    theta = Enum.random(saucer.thetas)
    velocity = %{saucer.velocity | theta: theta}
    {:noreply, %{saucer | velocity: velocity}}
  end

  def handle_info(:fire, %{game_id: game_id, tag: _tag} = saucer) do
    ref = make_ref()
    from = {self(), ref}
    :ok = GameServer.state_of_ship(game_id, self(), from)
    send_fire_after()
    {:noreply, saucer}
  end

  def handle_info({_ref, %Elixoids.Ship.Targets{} = targets}, %{accuracy: accuracy} = saucer) do
    if theta = select_target(targets) do
      bullet_theta = normalize_radians(theta + :rand.normal() * accuracy)
      publish_news_fires(saucer.game_id, saucer.tag)
      bullet_pos = turret(bullet_theta, saucer)
      {:ok, _pid} = GameServer.bullet_fired(saucer.game_id, saucer.tag, bullet_pos, bullet_theta)
      # Do we need to know when bullet ends?
      # Process.link(pid)
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

  def handle_cast({:bullet_hit_ship, _ship_tag}, saucer) do
    explode(saucer)
    {:stop, {:shutdown, :crashed}, saucer}
  end

  defp explode(saucer) do
    GameServer.explosion(saucer.game_id, saucer.pos, saucer.radius * 1.5)
  end

  @impl Elixoids.Game.Tick
  @spec handle_tick(any, any, %{
          game_id: integer,
          id: any,
          pos: any,
          radius: any,
          tag: any,
          theta: float
        }) :: {:ok, %{game_id: integer, id: any, pos: any, radius: any, tag: any, theta: float}}
  def handle_tick(_pid, delta_t_ms, saucer = %{game_id: game_id}) do
    next_saucer =
      update_in(saucer, [:pos], fn pos ->
        pos |> Velocity.apply_velocity(saucer.velocity, delta_t_ms) |> wrap()
      end)

    ship_loc = %ShipLoc{
      pid: self(),
      id: saucer.id,
      tag: saucer.tag,
      pos: next_saucer.pos,
      radius: saucer.radius,
      theta: Float.round(saucer.theta, 3)
    }

    GameServer.update_ship(game_id, ship_loc)
    {:ok, next_saucer}
  end

  defp random_saucer,
    do: %{
      pos: random_point_on_vertical_edge(),
      radius: saucer_radius_large(),
      theta: 0.0,
      velocity: Velocity.west(saucer_speed_m_per_s())
    }

  defp send_change_direction_after,
    do: Process.send_after(self(), :change_direction, @saucer_direction_change_interval)

  defp send_fire_after, do: Process.send_after(self(), :fire, saucer_shooting_interval())

  defp turret(theta, %{pos: ship_centre, radius: radius}) do
    Point.move(ship_centre, theta, radius * 1.1)
  end

  def select_target(%{origin: origin, rocks: rocks, ships: ships}) do
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
      |> filter_radar()
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

  defp filter_radar(targets) do
    max_r = saucer_radar_range()
    Enum.filter(targets, fn [t: _, d: d, r: _] -> d <= max_r end)
  end
end
