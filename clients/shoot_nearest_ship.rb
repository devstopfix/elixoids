require 'faye/websocket'
require 'eventmachine'
require 'json'

#
# This bot will always turn towards the closest ship,
# and fire at any ship in its current line of sight.
#

$SERVER = ENV['ELIXOIDS_SERVER'] || 'localhost:8065'

$RETRY_INTERVAL=5


def pointing_at(a,b)
  delta = (a-b).abs
  (delta <= 0.1) || (delta >= 6.2)
end

def sort_ships_by_distance(ships)
  ships.sort do |a,b|
    a[2] <=> b[2]
  end
end

def start_ship(ship_tag, retry_count)
  abort() unless retry_count > 0

  url = "ws://#{$SERVER}/0/ship/#{ship_tag}"
  target_id = nil
  EM.run {
    ws = Faye::WebSocket::Client.new(url)

    ws.on :open do |event|
      p [:open]
    end

    ws.on :message do |event|
        frame = JSON.parse(event.data)
        theta = frame['theta'] || 0.0
        opponents = frame['ships'] || []
        # Fire if we are pointing at any other ship
        if opponents.any? { |s| pointing_at(s[1], theta) }
          ws.send({:fire=>true}.to_json)
        end
        # Turn towards closes ship, or patrol
        if opponents.empty?
          second_hand = 360 - (Time.now.to_i % 360)
          theta = second_hand * Math::PI / 180
          ws.send({'theta'=>theta}.to_json)
        else
          target = sort_ships_by_distance(opponents).first
          tag, theta, dist = target
          ws.send({'theta'=>theta}.to_json)
          target_id = tag if target_id != tag
        end
    end

    ws.on :close do |event|
      p ["GAME OVER!", :close, event.code, event.reason]
      ws = nil
      sleep($RETRY_INTERVAL)
      start_ship(ship_tag, retry_count-1)
    end
  }
end

def default_killer_tag
  (['K'] << (0...2).map { (65 + rand(26)).chr }).join
end

start_ship(ARGV.first || default_killer_tag, 5)