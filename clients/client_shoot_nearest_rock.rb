require 'faye/websocket'
require 'eventmachine'
require 'json'


$SERVER = ENV['ELIXOIDS_SERVER'] || 'localhost:8065'


def fire?
  (rand(10)) == 0
end

def pointing_at(a,b)
  (a-b).abs < 0.50
end

def sort_ships_by_distance(ships)
  ships.sort do |a,b|
    a.last <=> b.last
  end
end

def start_ship(tag)
  url = "ws://#{$SERVER}/ship/#{tag}"
  puts sprintf("Piloting ship %s at %s", tag, url)
  target_id = nil

  EM.run {
    ws = Faye::WebSocket::Client.new(url)

    ws.on :open do |event|
      p [:open]
    end

    ws.on :message do |event|
      frame = JSON.parse(event.data)

      return unless frame.has_key?('rocks')

      rocks = frame['rocks']

      if rocks.empty?
        puts "Awaiting target..."
        return
      end

      candidates = sort_ships_by_distance(rocks)

      id, theta, radius, dist = candidates.first

      if (id != target_id)
        puts sprintf("%s Targeting %d at %f (of %d targets)", tag, id, theta, candidates.size)
      end

      shoot = pointing_at(theta, frame['theta'])
      ws.send({'theta'=>theta, 'fire'=>shoot}.to_json)

    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
      exit(1)
    end
  }
end

def default_tag
  (0...3).map { (65 + rand(26)).chr }.join
end

start_ship(ARGV.first || default_tag)
