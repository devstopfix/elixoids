defmodule Elixoids.Saucer.Server do
  @moduledoc """
  Flying saucer NPC!

  This server is not restarted if the Saucer is destroyed.
  """

  use GenServer, restart: :transient
  use Elixoids.Game.Heartbeat

  alias Elixoids.Game.Server, as: GameServer
  alias Elixoids.Ship.Location, as: ShipLoc
  alias Elixoids.World.Velocity

  import Elixoids.Const,
    only: [saucer_speed_m_per_s: 0, saucer_direction_change_interval: 0, large_saucer_radius: 0]

  import Elixoids.Space, only: [random_point_on_vertical_edge: 0, wrap: 1]
  import Elixoids.World.Angle, only: [normalize_radians: 1]

  @pi34 :math.pi() * 3 / 4.0
  @pi54 :math.pi() * 5 / 4.0
  @angles [@pi34, @pi34, :math.pi(), @pi54, @pi54]
  @saucer_direction_change_interval saucer_direction_change_interval()
  @tag "SČR"

  def start_link(game_id) do
    id = {game_id, @tag}

    saucer =
      random_saucer()
      |> Map.merge(%{
        game_id: game_id,
        tag: @tag,
        thetas: Enum.map(@angles, &normalize_radians/1),
        id: id
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
    Process.send_after(self(), :change_direction, @saucer_direction_change_interval)
    {:ok, saucer}
  end

  def handle_info(:change_direction, saucer) do
    Process.send_after(self(), :change_direction, @saucer_direction_change_interval)
    theta = Enum.random(saucer.thetas)
    velocity = %{saucer.velocity | theta: theta}
    {:noreply, %{saucer | velocity: velocity}}
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
      radius: large_saucer_radius(),
      theta: 0.0,
      velocity: Velocity.west(saucer_speed_m_per_s())
    }
end
