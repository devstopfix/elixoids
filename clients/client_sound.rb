require 'faye/websocket'
require 'eventmachine'
require 'json'

$SERVER = ENV['ELIXOIDS_SERVER'] || 'localhost:8065'
$SOCKET = "ws://#{$SERVER}/sound"

def start()
  EM.run {
    ws = Faye::WebSocket::Client.new($SOCKET)

    ws.on :open do |event|
      p [:open]
    end

    ws.on :message do |event|
      state = JSON.parse(event.data)
      explosions = state['x']
      puts explosions.inspect unless explosions.empty?
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end
  }
end

start()