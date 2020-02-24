defmodule Elixoids.Saucer.Server do
  @moduledoc """
  Flying saucer NPC!
  """

  use GenServer
  use Elixoids.Game.Heartbeat

  alias Elixoids.Game.Server, as: GameServer
  alias Elixoids.Ship.Location, as: ShipLoc
  alias Elixoids.World.Velocity

  import Elixoids.Const, only: [saucer_speed_m_per_s: 0, saucer_direction_change_interval: 0]
  import Elixoids.Space, only: [random_point_on_vertical_edge: 0, wrap: 1]

  @angles [:math.pi() * 3 / 4.0, :math.pi(), :math.pi() * 5 / 4.0]
  @saucer_direction_change_interval saucer_direction_change_interval()
  @tag "SČR"

  def start_link(game_id) do
    saucer =
      random_saucer()
      |> Map.merge(%{game_id: game_id, tag: @tag, id: {game_id, @tag}})

    GenServer.start_link(__MODULE__, saucer)
  end

  @impl true
  def init(saucer) do
    Process.flag(:trap_exit, true)
    start_heartbeat()
    Process.send_after(self(), :change_direction, @saucer_direction_change_interval)
    {:ok, saucer}
  end

  def handle_info(:change_direction, saucer) do
    Process.send_after(self(), :change_direction, @saucer_direction_change_interval)
    theta = Enum.random(@angles)
    velocity = %{saucer.velocity | theta: theta}
    {:noreply, %{saucer | velocity: velocity}}
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
      radius: 20.0 * (20 / 13.0),
      theta: 0.0,
      velocity: Velocity.west(saucer_speed_m_per_s())
    }
end
