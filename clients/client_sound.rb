require 'websocket-client-simple'
require 'json'

$SERVER = ENV['ELIXOIDS_SERVER'] || 'localhost:8065'
$SOCKET = "ws://#{$SERVER}/sound"

$finished = false

WebSocket::Client::Simple.connect $SOCKET do |ws|

  ws.on :open do
    puts "Connected to " << $SOCKET
  end

  ws.on :message do |msg|
    state = JSON.parse(msg.data)
    explosions = state['x']
    puts explosions.inspect unless explosions.empty?
  end

  ws.on :error do |e|
    p e
    $finished = true
  end

  ws.on :close do |e|
    p e
    puts "GAME OVER!"
    $finished = true
  end

end

while not $finished do
end
