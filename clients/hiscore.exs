defmodule Hiscore do

  defmodule Stats do
    use GenServer

    @impl true
    def init(_), do: { :ok, %{accuracy: %{}, crashes: %{}, kills: %{}, miner: %{}} }

    @impl true
    def handle_info(["ASTEROID", "hit", player], state) do
      new_state = update_in(state, [:crashes, player], &player_crashed/1)
      {:noreply, new_state}
    end

    @impl true
    def handle_info([player, "fires"], state) do
      new_state = update_in(state, [:accuracy, player], &player_fired/1)
      IO.inspect(new_state)
      {:noreply, new_state}
    end

    @impl true
    def handle_info([player, "shot", "ASTEROID"], state) do
      new_state = state
      |> update_in([:miner, player], &player_shot_asteroid/1)
      |> update_in([:accuracy, player], &player_hit_target/1)

      {:noreply, new_state}
    end

    @impl true
    def handle_info([player, "shot", _other], state) do
      new_state = state
      |> update_in([:accuracy, player], &player_hit_target/1)

      {:noreply, new_state}
    end

    @impl true
    def handle_info([player, "kills", other], state) do
      new_state = state
      |> update_in([:accuracy, player], &player_hit_target/1)
      |> update_in([:kills, player], fn stats -> player_kills(stats, other) end)

      {:noreply, new_state}
    end


    @impl true
    def handle_info(["ASTEROID", "spotted"], state), do: {:noreply, state}

    @impl true
    def handle_info(msg, state) do
      IO.inspect([ignored: msg])
      {:noreply, state}
    end

    # @impl true
    # def handle_info(_, state), do: {:noreply, state}


    defp player_fired(nil), do: {1, 0, 0.0}
    defp player_fired({f, h, _p}), do: {f+1, h, Float.round(h / (f + 1), 3)}

    defp player_hit_target(nil), do: {1, 1, 0.0}
    defp player_hit_target({f, h, _p}), do: {f, h+1, Float.round((h+1) / f, 3)}

    defp player_shot_asteroid(nil), do: 1
    defp player_shot_asteroid(n), do: n + 1

    defp player_crashed(nil), do: 1
    defp player_crashed(n), do: n + 1

    defp player_kills(nil, other), do: Map.put(%{}, other, 1)
    defp player_kills(stats, other), do: Map.update(stats, other, 1, &(&1 + 1))

  end


  defmodule Stream do
    use GenServer

    @impl true
    def init([url, stats]) do
      {:ok, _ref} = :httpc.request(:get, {url, []}, [], [sync: false, stream: :self])
      {:ok, stats}
    end

    @impl true
    def handle_info({:http, {_ref, :stream, "data: " <> line}}, stats) do
      msg = line |> String.trim |> String.split
      :ok = Process.send(stats, msg, [])
      {:noreply, stats}
    end

    @impl true
    def handle_info({:http, {_ref, :stream_start, _e}}, stats), do: {:noreply, stats}

    @impl true
    def handle_info(msg, stats) do
      [unexpected: msg] |> inspect |> IO.puts
      {:noreply, stats}
    end

  end



  # def receive_data(_requestId) do
  #   receive do
  #       {:http, msg} -> IO.inspect(msg)
  #   after 150000 ->
  #     IO.inspect(:timeout)
  #   end
  # end


  # def stream(url, pid) do
  #   {:ok, _} = :httpc.request(:get, {'http://localhost:8065/0/news', []}, [], [sync: false, stream: :self])

  # end

end

:inets.start()

# {:ok, requestId} = :httpc.request(:get, {'http://localhost:8065/0/news', []}, [], [sync: false, stream: :self])

{:ok, stats} = GenServer.start_link(Hiscore.Stats, [])

{:ok, _pid} = GenServer.start_link(Hiscore.Stream, ['http://localhost:8065/0/news', stats])

# Enum.each(1..10, fn _ -> Hiscore.receive_data(requestId) end)

# Hiscore.stream(url, pid)


#

