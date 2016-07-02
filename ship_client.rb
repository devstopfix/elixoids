require 'faye/websocket'
require 'eventmachine'
require 'json'

$SHIP = ARGV.first || 'XXX'

EM.run {
  ws = Faye::WebSocket::Client.new("ws://localhost:8065/ship/#{$SHIP}")

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
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
