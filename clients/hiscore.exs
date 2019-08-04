defmodule Hiscore do
  @moduledoc """
  Listens to the news feed of an Elixoids game and calculates high-scores.

  Run with:

      elixir --no-halt clients/hiscore.exs http://localhost:8065/0/news
  """

  defmodule Stats do
    use GenServer

    @impl true
    def init(_), do: {:ok, %{accuracy: %{}, crashes: %{}, kills: %{}, miner: %{}, score: %{}}}

    @impl true
    def handle_info(["ASTEROID", "hit", player], state) do
      new_state = update_in(state, [:crashes, player], &player_crashed/1)
      {:noreply, new_state}
    end

    @impl true
    def handle_info([player, "fires"], state) do
      new_state = update_in(state, [:accuracy, player], &player_fired/1)
      {:noreply, new_state}
    end

    @impl true
    def handle_info([player, "shot", "ASTEROID"], state) do
      new_state =
        state
        |> update_in([:miner, player], &player_shot_asteroid/1)
        |> update_in([:accuracy, player], &player_hit_target/1)
        |> update_in([:score, player], &player_score(&1, :asteroid))

      Hiscore.Printer.print(new_state)

      {:noreply, new_state}
    end

    @impl true
    def handle_info([player, "shot", _other], state) do
      new_state =
        state
        |> update_in([:accuracy, player], &player_hit_target/1)

      {:noreply, new_state}
    end

    @impl true
    def handle_info([player, "kills", other], state) do
      new_state =
        state
        |> update_in([:accuracy, player], &player_hit_target/1)
        |> update_in([:kills, player], fn stats -> player_kills(stats, other) end)
        |> update_in([:score, player], &player_score(&1, :kill))

      {:noreply, new_state}
    end

    @impl true
    def handle_info(["ASTEROID", "spotted"], state), do: {:noreply, state}

    @impl true
    def handle_info(msg, state) do
      [:red, :bright, inspect(msg)] |> IO.ANSI.format(true) |> IO.puts()
      {:noreply, state}
    end

    defp player_fired(nil), do: {1, 0, 0.0}
    defp player_fired({f, h, _p}) when h <= f, do: {f + 1, h, pct(h / (f + 1))}
    defp player_fired({f, h, _p}), do: {f + 1, h, 1.0}

    defp player_hit_target(nil), do: {1, 1, 0.0}
    defp player_hit_target({f, h, _p}) when h < f, do: {f, h + 1, pct((h + 1) / f)}
    defp player_hit_target({f, h, _p}), do: {f, h + 1, 1.0}

    defp player_shot_asteroid(nil), do: 1
    defp player_shot_asteroid(n), do: n + 1

    defp player_crashed(nil), do: 1
    defp player_crashed(n), do: n + 1

    defp player_kills(nil, other), do: Map.put(%{}, other, 1)
    defp player_kills(stats, other), do: Map.update(stats, other, 1, &(&1 + 1))

    defp player_score(nil, :kill), do: player_score(0, :kill)
    defp player_score(s, :kill), do: s + 1

    defp player_score(nil, :asteroid), do: player_score(0, :asteroid)
    defp player_score(s, :asteroid), do: s + 3

    defp pct(f), do: Float.round(f, 3)
  end

  defmodule Printer do
    @moduledoc "Prints the scores to STDOUT."

    def print(state) do
      IO.puts("\n\n\n\nHI-SCORE:\n--------\n")
      state.score
      |> score()
      |> print_data()

      IO.puts("\n\nACCURACY (shots that hit target):\n")
      state.accuracy
      |> accuracy()
      |> print_data()

      IO.puts("\n\nMINERS (most asteroids hit vs crashes):\n")
      state.miner
      |> miners(state.crashes)
      |> print_data()

      IO.puts("\n\nHUNTERS (most opponents killed):\n")
      state.kills
      |> hunters()
      |> print_data()

      IO.puts("\n\nHUNTED (most killed):\n")
      state.kills
      |> hunted(state.crashes)
      |> print_data()

    end

    def print_data(data), do: data |> Hiscore.Table.format_table() |> IO.puts()

    defp accuracy(data) do
      results =
        data
        |> Enum.map(fn {tag, {fired, hits, acc}} -> [tag, acc, fired, hits] end)
        |> Enum.sort(fn [t1, _, _, _], [t2, _, _, _] -> t1 > t2 end)
        |> Enum.sort(fn [_, a1, _, _], [_, a2, _, _] -> a1 > a2 end)

      [["PLAYR", "%", "SHOTS", "HITS"], ["―", "―", "―", "―"]]
      |> Enum.concat(drop_middle(results))
    end

    # Merge players shot into players hit with asteroids
    defp hunted(data, crashes_data) do

      results =
        data
        |> Map.values()
        |> Enum.reduce(crashes_data, fn kills, results -> Map.merge(results, kills, fn _, a, b -> a + b end) end)
        |> Enum.map(&Tuple.to_list/1)
        |> Enum.sort(fn [t1, _s1], [t2, _s2] -> t1 > t2 end)
        |> Enum.sort(fn [_t1, s1], [_t2, s2] -> s1 > s2 end)

      [["PLAYR", "DEATH"], ["―", "―"]]
      |> Enum.concat(drop_middle(results))
    end

    defp hunters(data) do
      results =
        data
        |> Enum.map(fn {tag, kills} -> [tag, kills |> Map.values() |> Enum.sum()] end)
        |> Enum.sort(fn [t1, _s1], [t2, _s2] -> t1 > t2 end)
        |> Enum.sort(fn [_t1, s1], [_t2, s2] -> s1 > s2 end)

      [["PLAYR", "KILLS"], ["―", "―"]]
      |> Enum.concat(drop_middle(results))
    end

    defp miners(data, crashes) do
      results =
        data
        |> Enum.map(&Tuple.to_list/1)
        |> Enum.map(fn [tag, score] -> [tag, score, Map.get(crashes, tag, "")] end)
        |> Enum.sort(fn [t1, _s1, _], [t2, _s2, _] -> t1 > t2 end)
        |> Enum.sort(fn [_t1, s1, _], [_t2, s2, _] -> s1 > s2 end)

      [["PLAYR", "ROCKS", "CRASH"], ["―", "―", "―"]]
      |> Enum.concat(drop_middle(results))
    end

    defp score(data) do
      results =
        data
        |> Enum.map(&Tuple.to_list/1)
        |> Enum.sort(fn [t1, _s1], [t2, _s2] -> t1 > t2 end)
        |> Enum.sort(fn [_t1, s1], [_t2, s2] -> s1 > s2 end)

      [["PLAYR", "SCORE"], ["―", "―"]]
      |> Enum.concat(drop_middle(results))
    end

    defp drop_middle(results, rows \\ 2) do
      top = results |> Enum.take(rows)

      bottom =
        results |> Enum.drop(rows) |> Enum.reverse() |> Enum.take(rows) |> Enum.reverse()

      top
      |> Enum.concat([[]])
      |> Enum.concat(bottom)
    end
  end

  defmodule Table do
    @moduledoc "Convert data to ASCII tables"

    def column_width, do: 5

    defprotocol Column do
      @doc "Format for column"
      def to_column(v)
    end

    defimpl Column, for: BitString do
      def to_column("―"), do: String.pad_trailing("", Table.column_width(), "―")
      def to_column(v), do: String.pad_trailing(v, Table.column_width(), " ")
    end

    defimpl Column, for: String do
      def to_column(v), do: String.pad_trailing(v, Table.column_width(), " ")
    end

    defimpl Column, for: Float do
      def to_column(f),
        do:
          f
          |> Float.round(3)
          |> Float.to_string()
          |> String.pad_trailing(5, "0")
          |> String.pad_leading(Table.column_width(), " ")
    end

    defimpl Column, for: Integer do
      def to_column(i),
        do: i |> Integer.to_string() |> String.pad_leading(Table.column_width(), " ")
    end

    def format_table(rows) do
      rows
      |> Enum.map(&format_row/1)
      |> Enum.join("\n")
    end

    defp format_row([]), do: "⋮"

    defp format_row(row) do
      row
      |> Enum.map(&Column.to_column/1)
      |> Enum.join(" ")
    end
  end

  defmodule Stream do
    use GenServer

    # https://tools.ietf.org/html/rfc6455#section-5.6
    @data_frame "data:"

    @impl true
    def init([["http" <> _ = url], stats]) do
      {:ok, _ref} = :httpc.request(:get, {to_charlist(url), []}, [], sync: false, stream: :self)
      {:ok, stats}
    end

    @impl true
    def handle_info({:http, {_ref, :stream, @data_frame <> " " <> line}}, stats) do
      line
      |> String.split()
      |> Enum.chunk_by(fn s -> s != @data_frame end)
      |> Enum.filter(fn l -> Enum.count(l) > 1 end)
      |> Enum.each(fn event -> :ok = Process.send(stats, event, []) end)

      {:noreply, stats}
    end

    @impl true
    def handle_info({:http, {_ref, :stream, line}}, stats) do
      IO.ANSI.format([:red, :bright, line], true) |> IO.puts()
      {:noreply, stats}
    end

    @impl true
    def handle_info({:http, {_ref, :stream_start, _e}}, stats), do: {:noreply, stats}

    @impl true
    def handle_info(_, stats) do
      {:noreply, stats}
    end
  end
end

:ok = Application.ensure_started(:inets)
# :ok = Application.ensure_started(:ssl)
{:ok, stats} = GenServer.start_link(Hiscore.Stats, [])
{:ok, _pid} = GenServer.start_link(Hiscore.Stream, [System.argv(), stats])
