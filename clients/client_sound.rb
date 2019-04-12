require 'faye/websocket'
require 'eventmachine'
require 'json'

$SERVER = ENV['ELIXOIDS_SERVER'] || 'localhost:8065'

$finished = false

def run()

  url = "ws://#{$SERVER}/sound"

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
      # explosions = state['x']
      # puts explosions.inspect unless explosions.empty?
    end

    ws.on :error do |e|
      p e
      abort()
    end

    ws.on :close do |e|
      p e
      puts "GAME OVER!"
      $finished = true
      abort()
    end
  }
end

run()