require 'faye/websocket'
require 'eventmachine'
require 'json'

$SERVER = ENV['ELIXOIDS_SERVER'] || 'localhost:8065'

$GAME_ID = "0"

def run()

  url = "ws://#{$SERVER}/#{$GAME_ID}/sound"

  EM.run {
    ws = Faye::WebSocket::Client.new(url)

    ws.on :open do |event|
      p [:open]
    end

    ws.on :message do |msg|
      begin
        state = JSON.parse(msg.data)
        puts state unless state.empty?
      rescue
        puts msg
      end
    end

    ws.on :error do |e|
      p e
      abort()
    end

    ws.on :close do |e|
      puts "GAME OVER!"
      abort()
    end
  }
end

run()