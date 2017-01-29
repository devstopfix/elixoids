defmodule Game.Collision do

  @moduledoc """
  Simplistic collision detections.
  Runs as a separate process to avoid slowing game loop in busy screens.
  Tests everything against everything else - no bounding boxes or culling.
  """

  use GenServer

  alias Game.Server, as: Game
  alias World.Point, as: Point
  require World.Point

  def start_link(game_pid, world_dimensions) do
    GenServer.start_link(__MODULE__, {:ok, game_pid, world_dimensions}, [])
  end

  def collision_tests(pid, game) do
    GenServer.cast(pid, {:collision_tests, game})
  end

  def ships(pid, ships, world_dimensions) do
    GenServer.cast(pid, {:ships, ships, world_dimensions})    
  end

  @doc """
  List of bullets (bullet_ids) to stop.
  """
  def unique_bullets(collisions) do
    collisions
    |> Enum.map(fn {b,_} -> b end)
    |> Enum.uniq
  end

  @doc """
  List of targets (ship_ids) to destroy
  """
  def unique_targets(collisions) do
    collisions
    |> Enum.map(fn {_,s} -> s end)
    |> Enum.uniq
  end

  # GenServer

  defp stats_filename do
    ["/tmp/elixoids.", :os.system_time(:millisecond), ".csv"] |> Enum.join
  end

  def init({:ok, game_pid, world_dimensions}) do
    f=stats_filename() |> File.open!([:write, :utf8])
    IO.write(f, CSVLixir.write_row(["t", "elapsed", "ships", "rocks", "bullets", "sum_ob", "prod_ob"]))
    {:ok, %{game_pid: game_pid, 
            dim: world_dimensions,
            csv: f, 
            ships_qt: :erlquad.new(0, 0, 100, 100, 1)}}
  end

  # TODO remove
  def terminate(_reason, state) do
    File.close(state.csv)
    :normal
  end


  @doc """
  Build a new quadtree whenever the ships move or change.
  Then check to see if any ships collide.
  """
  def handle_cast({:ships, ships, world_dimensions}, state) do
    ships_qt = quadtree(world_dimensions, ships, fn s->s end)
    # TODO Ship Collisions
    #GenServer.cast(self(), :test_ship_collisions) 
    {:noreply, Map.put(state, :ships_qt, ships_qt)}
  end

  @doc """
  DODO Test all ships in the world to see if they overlap any others
  """
  def handle_cast(:test_ship_collisions, state) do
    :erlquad.objects_all(state.ships_qt)
    |> Enum.flat_map(fn({:ship, _, x, y, r})->
      :erlquad.area_query(x-r,y-r,x+r,y+r, state.ships_qt)
      |> Enum.chunk(2,2)
      |> Enum.map(fn([{:ship, id1, _, _, _}, {:ship, id2, _, _, _}])->
        {:ships_collide, id1, id2}
      end)
    end)
    |> Enum.uniq
    |> Enum.each(fn {:ships_collide, id1, id2} -> Game.ships_collide(state.game_pid, id1, id2) end)
    {:noreply, state}
  end

  # Collisions

  def handle_cast({:collision_tests, game}, state) do
    fn -> check_for_collisions(game, state.game_pid, state.ships_qt, state.dim) end
    |> :timer.tc
    |> elem(0)
    |> write_stats(game, state.csv)

    {:noreply, state}
  end

  # TODO remove
  defp write_stats(elapsed, game, csv) do
    counts = game.state
    |> Enum.reduce(%{}, fn({k,v}, acc) -> Map.put(acc, k, Enum.count(v)) end)

    row = [:os.system_time(:millisecond),
     elapsed,
     counts.ships,
     counts.asteroids,
     counts.bullets,
     Enum.sum(Map.values(counts)),
     Enum.reduce(Map.values(counts), 1, fn(x, acc) -> acc * max(1,x) end)]
     |> CSVLixir.write_row

     IO.write(csv, row)
  end


  defp check_for_collisions(game, game_pid, ships_qt, dim) do
    asteroids_qt = quadtree(dim, Map.values(game.state.asteroids))

    game.state.bullets
    |> Map.values
    |> bullets_on_ships(ships_qt)
    |> stop_ships(game_pid)
    |> stop_bullets(game_pid)
    |> bullets_on_asteroids(asteroids_qt)
    |> stop_asteroids(game_pid)
    |> stop_bullets(game_pid)

    check_for_collisions(game_pid, ships_qt, asteroids_qt)
  end

  defp check_for_collisions(game_pid, ships_qt, asteroids_qt) do
    Enum.each(:erlquad.objects_all(ships_qt), fn {:ship, ship_id, sx, sy, sr} ->
      case circle_query(asteroids_qt, sx, sy, sr) do
        {asteroid_id, _ax, _ay, _} -> Game.asteroid_hit_ship(game_pid, asteroid_id, ship_id)
        nil -> false
      end
    end)
  end

  # Remove all collisions from the events and stop the bullets.
  # Return all events that are not collisions.
  defp stop_bullets(events, game_pid) do
    Enum.filter(events, fn(e) -> 
      case e do
        {:bullet, id, :hits, _, _} -> Game.stop_bullet(game_pid, id); false
        _ -> true
      end
    end)
  end

  #
  # Handle bullets hitting ships
  #

  defp stop_ship({:bullet, bullet_id, :hits, :ship, ship_id}, game_pid) do
    Game.detonate_ship(game_pid, ship_id)
    Game.hyperspace_ship(game_pid, ship_id)    
    Game.say_player_shot_ship(game_pid, bullet_id, ship_id)
  end 

  defp stop_ship(_, _game_pid) do end 

  defp stop_ships(events, game_pid) do
    Enum.each(events, fn e -> stop_ship(e, game_pid) end)
    events
  end

  #
  # Bullets hitting asteroids
  #

  defp stop_asteroid({:bullet, _bullet_id, :hits, :asteroid, asteroid_id}, game_pid) do
    Game.asteroid_hit(game_pid, asteroid_id)
  end 

  defp stop_asteroid(_, _game_pid) do end 

  defp stop_asteroids(events, game_pid) do
    Enum.each(events, fn e -> stop_asteroid(e, game_pid) end)
    events
  end

  @doc """
  Tests a list of bullets against a quadtree of ships.
  Returns a list of tuples containing collisions or unimpeded bullets
  """

  def bullets_on_ships(bullets, qt_ships) do
    Enum.map(bullets, fn {id, bx, by} ->
      case point_query(qt_ships, bx, by, :ship) do
        {:ship, ship_id, _, _, _} -> {:bullet, id, :hits, :ship, ship_id}
        nil -> {:bullet, id, bx, by}
      end
    end)
  end

  @doc """
  Test a list of bullets against a quadtree of asteroids.
  Return a list of tuples containing collisions or unimpeded bullets
  """
  def bullets_on_asteroids(bullets, asteroids_qt) do
    Enum.map(bullets, fn {:bullet, id, bx, by} ->
      case point_query(asteroids_qt, bx, by) do
        {asteroid_id, _, _, _} -> {:bullet, id, :hits, :asteroid, asteroid_id}
        nil -> {:bullet, id, bx, by}
      end
    end)    
  end

  # Quadtree constructor

  defp identify_fn(x) do x end

  @doc """
  Create a quadtree containing the given items.
  Items are a list of tuples.
  """
  def quadtree(world_dimensions, items) do quadtree(world_dimensions, items, &identify_fn/1) end

  @quadtree_depth 4

  @doc """
  Create a quadtree containing the given items.
  The `identify` function should convert an item into a tuple.
  """
  def quadtree(world_dimensions, items, identify) do
    [x,y] = world_dimensions
    qt = :erlquad.new(0, 0, x, y, @quadtree_depth)
    :erlquad.objects_add(Enum.map(items, identify), &bounding_box/1, qt)
  end

  @doc """
  Return the first object in the quadtree that collides with point [px,py],
  otherwise nil.
  """
  def point_query(qt, px, py) do
    :erlquad.area_query(px, py, px, py, qt)
    |> Enum.find(nil, fn {_id, x, y, r} -> Point.point_inside_circle?(px, py, x, y, r) end)
  end

  def point_query(qt, px, py, _tag) do
    :erlquad.area_query(px, py, px, py, qt)
    |> Enum.find(nil, fn {_tag, _id, x, y, r} -> Point.point_inside_circle?(px, py, x, y, r) end)
  end

  @doc """
  Return the first object in the quadtree that collides with a circle centered at [px,py],
  otherise nil.
  """
  def circle_query(qt, px, py, radius) do
    :erlquad.area_query(px-radius, py-radius, px+radius, py+radius, qt)
    |> Enum.find(nil, fn {_, x, y, r} -> Point.circles_intersect?({px, py, radius}, {x, y, r}) end)    
  end

  # Bounding box of ship is a square with dimensions 2×radius
  defp bounding_box({:ship, _, x, y, r}) do
    {x-r,y-r,x+r,y+r}
  end

  defp bounding_box({_, x, y, r}) do
    {x-r,y-r,x+r,y+r}
  end

end
