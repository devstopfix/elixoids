defmodule Elixoids.Server.WebsocketSoundHandler do
  @moduledoc "Forwards game sounds to the subscriber."

  alias Elixoids.Api.Sound, as: SoundProtocol

  @opts %{idle_timeout: 60 * 60 * 1000}

  @behaviour :cowboy_handler

  def init(
        req = %{headers: %{"accept" => "application/octet-stream"}, bindings: %{game: game}},
        _opts
      ) do
    state = %{encode: &encode_protocol/2, game: game}
    {:cowboy_websocket, req, state, @opts}
  end

  def init(req = %{bindings: %{game: game}}, _opts) do
    state = %{encode: &encode_json/2, game: game}
    {:cowboy_websocket, req, state, @opts}
  end

  def websocket_init(state = %{game: game}) do
    with {game_id, ""} <- Integer.parse(game),
         {:ok, _pid} <- Elixoids.News.subscribe(game_id) do
      {:ok, state}
    else
      :error -> {:stop, state}
    end
  end

  def websocket_terminate(_reason, _req, _state), do: :ok

  def websocket_handle(_data, state), do: {:ok, state}

  def websocket_info({:audio, sound}, state = %{encode: encode}), do: encode.(sound, state)

  def websocket_info(_, state), do: {:ok, state}

  defp encode_json(sound, state) do
    case Jason.encode([sound]) do
      {:ok, payload} -> {:reply, {:text, payload}, state}
      _ -> {:ok, state}
    end
  end

  defp encode_protocol(sound, state), do: {:reply, {:binary, SoundProtocol.encode(sound)}, state}
end
