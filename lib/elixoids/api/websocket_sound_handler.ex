defmodule Elixoids.Api.WebsocketSoundHandler do
  @moduledoc "Forwards game sounds to the subscriber."

  alias Elixoids.Api.Sound.Protocol, as: SoundProtocol
  import Logger

  @opts %{idle_timeout: 60 * 60 * 1000}

  @behaviour :cowboy_handler

  def init(req = %{headers: %{"accept" => "application/octet-stream"}}, _opts) do
    state = %{encode: &encode_protocol/2}
    {:cowboy_websocket, req, state, @opts}
  end

  def init(req, _opts) do
    state = %{encode: &encode_json/2}
    {:cowboy_websocket, req, state, @opts}
  end

  # TODO get game ID from URL
  def websocket_init(state) do
    {:ok, _pid} = Elixoids.News.subscribe(0)
    [:ws_connection, :audio] |> inspect |> info()
    {:ok, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    [:ws_disconnect, :audio] |> inspect |> info()
    :ok
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def websocket_info({:audio, sound}, state = %{encode: encode}) do
    encode.(sound, state)
  end

  def websocket_info(_, state) do
    {:ok, state}
  end

  defp encode_json(sound, state) do
    case Jason.encode([sound]) do
      {:ok, payload} -> {:reply, {:text, payload}, state}
      _ -> {:ok, state}
    end
  end

  defp encode_protocol(sound, state), do: {:reply, {:binary, SoundProtocol.encode(sound)}, state}
end
