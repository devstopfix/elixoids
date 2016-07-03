require 'faye/websocket'
require 'eventmachine'
require 'json'

def fire?
  (rand(10)) == 0
end

def pointing_at(a,b)
  (a-b).abs < 0.1
end

def sort_ships_by_distance(ships)
  ships.sort do |a,b|
    a[2] <=> b[2]
  end
end

def start_ship(tag)
  url = "ws://localhost:8065/ship/#{tag}"
  EM.run {
    ws = Faye::WebSocket::Client.new(url)

    ws.on :open do |event|
      p [:open]
    end

    ws.on :message do |event|
      next unless event.data.start_with? '{'
      frame = JSON.parse(event.data)
      puts frame.inspect
      if frame.has_key?('ships')
        unless frame['ships'].empty?
          target = sort_ships_by_distance(frame['ships']).first
          tag, theta = target
          puts theta
          ws.send({'theta'=>theta}.to_json)
          ws.send({:fire=>true}.to_json) if pointing_at(theta, frame['theta'])
        end
      end

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