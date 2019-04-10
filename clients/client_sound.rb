require 'faye/websocket'
require 'eventmachine'
require 'json'

$SERVER = ENV['ELIXOIDS_SERVER'] || 'localhost:8065'

$finished = false

def run()

  url = "ws://#{$SERVER}/sound"

  EM.run {
    ws = Faye::WebSocket::Client.new(url)


    ws.on :message do |msg|
      state = JSON.parse(msg.data)
      explosions = state['x']
      puts explosions.inspect unless explosions.empty?
    end

    ws.on :error do |e|
      p e
      $finished = true
    end

    ws.on :close do |e|
      p e
      puts "GAME OVER!"
      $finished = true
    end
  }
end

run()