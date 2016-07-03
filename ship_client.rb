require 'faye/websocket'
require 'eventmachine'
require 'json'

def fire?
  (rand(10)) == 0
end

def start_ship(tag)
  url = "ws://localhost:8065/ship/#{tag}"
  EM.run {
    ws = Faye::WebSocket::Client.new(url)

    ws.on :open do |event|
      p [:open]
    end

    ws.on :message do |event|
      puts Time.now
      puts event.data
      # frame = JSON.parse(event.data)
      # unless frame['x'].empty?
      #   frame['x'].each do |xplosion|
      #     x,y = xplosion
      #     p "Explosion at #{x.to_s}, #{y.to_s}"
      #   end
      # end
      
      ws.send({:fire=>true}.to_json) if fire?

      t = (Time.now.to_i % 6).to_f
      ws.send({'theta'=>t}.to_json) if fire?
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end
  }
end

def default_tag
  (0...3).map { (65 + rand(26)).chr }.join
end

$SHIP = ARGV.first || default_tag
start_ship($SHIP)