require 'faye/websocket'
require 'eventmachine'
require 'json'
require 'logger'

@logger = Logger.new(STDOUT)

$RETRY_INTERVAL=5

#
# This bot will turn towards the largest rock,
# and fire at any rock along its line of site.
#
# Note that it will turn towards the current position
# of the rock and so will usually miss the target
# unless the rock is large or moving directly towards
# or away.
#

$SERVER = ENV['ELIXOIDS_SERVER'] || 'localhost:8065'


def pointing_at(rock_theta, ship_theta)
  delta = (rock_theta-ship_theta).abs
  (delta <= 0.2) || (delta >= 6.08)
end

def sort_by_size(rocks)
  rocks.sort do |a,b|
    a_id, _, a_radius, a_dist = a
    b_id, _, b_radius, b_dist = b

    b_radius <=> a_radius
  end
end

def round(theta)
  if (theta < 0.0)
    theta + (2 * Math::PI)
  else
    theta
  end
end

def perturb(theta)
  theta - 0.2 + (rand() * 0.4)
end

def start_ship(tag, retry_count)
  abort() unless retry_count > 0

  @tag = tag
  url = "ws://#{$SERVER}/ship/#{tag}"
  @logger.info(sprintf("Piloting ship %s at %s", tag, url))
  target_id = nil

  EM.run {
    ws = Faye::WebSocket::Client.new(url)

    ws.on :open do |event|
      @logger.info [tag, :open]
    end

    ws.on :message do |event|
      frame = JSON.parse(event.data)
      rocks = frame['rocks'] || []

      if rocks.any? { |a| pointing_at(a[1], frame['theta'])}
        ws.send({'fire'=>true}.to_json)
      end

      unless rocks.empty?
        candidates = sort_by_size(rocks)
        id, theta, radius, dist = candidates.first
        theta_rnd = round(perturb(theta))
        ws.send({'theta'=>theta_rnd}.to_json)
        if (id != target_id)
          @logger.info(sprintf("%s Targeting %d at %f (of %d targets)", tag, id, theta, candidates.size))
          target_id = id
        end
      end
    end

    ws.on :close do |event|
      @logger.info([:close, event&.code, event&.reason])
      ws = nil
      sleep($RETRY_INTERVAL)
      start_ship(@tag, retry_count-1)
    end
  }
end

def default_tag
  (0...3).map { (65 + rand(26)).chr }.join
end

start_ship(ARGV.first || default_tag, 5)
