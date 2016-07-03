require 'faye/websocket'
require 'eventmachine'
require 'json'

def fire?
  (Time.now.to_i % 3) == 0
end

def start_ship(tag)
  url = "ws://localhost:8065/ship/#{tag}"
  EM.run {
    ws = Faye::WebSocket::Client.new(url)

    ws.on :open do |event|
      p [:open]
    end

    ws.on :message do |event|
      puts event.data
      # frame = JSON.parse(event.data)
      # unless frame['x'].empty?
      #   frame['x'].each do |xplosion|
      #     x,y = xplosion
      #     p "Explosion at #{x.to_s}, #{y.to_s}"
      #   end
      # end
      ws.send({:fire=>true}.to_json) if fire?
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end
  }
end

$SHIP = ARGV.first || 'PLY'
start_ship($SHIP)