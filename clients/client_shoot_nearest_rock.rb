require 'faye/websocket'
require 'eventmachine'
require 'json'


$SERVER = ENV['ELIXOIDS_SERVER'] || 'localhost:8065'


def fire?
  (rand(10)) == 0
end

def pointing_at(rock_theta, ship_theta)
  delta = (rock_theta-ship_theta).abs
  (delta <= 0.1) || (delta >= 6.2)
end

def sort_ships_by_distance(ships)
  ships.sort do |a,b|
    a.last <=> b.last
  end
end

def round(theta)
  if (theta < 0.0)
    theta + (2 * Math::PI)
  else
    theta
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

      shoot = rocks.any? { |a| pointing_at(a[1], frame['theta'])} 
      ws.send({'theta'=>round(theta), 'fire'=>shoot}.to_json)
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
