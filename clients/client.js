// Import the WebSocket library with `npm install ws`
const WebSocket = require('ws');
// Import the readline module to read keypresses
const readline = require('readline');

// --- Configuration ---
// Change your ship name to your initials
const YOUR_NAME_3 = 'YOUXX'
const SERVER = '54.251.134.162'
const SERVER_ADDRESS = 'ws://' + SERVER + '/0/ship/' + YOUR_NAME_3;

// --- WebSocket Connection ---
console.log(`Connecting to ${SERVER_ADDRESS}`);
const ws = new WebSocket(SERVER_ADDRESS);

// --- Event Handlers ---

// Handle the connection opening
ws.on('open', function open() {
  console.log('Press "j" for LEFT, "k" for RIGHT, SPACE for FIRE. Press CTRL+C to exit.');
});

// Handle incoming messages from the server
ws.on('message', function incoming(data) {
  console.log(`Game state from server: ${data}`);
});

// Handle connection errors
ws.on('error', function error(err) {
  console.error('Connection Error:', err.message);
  process.exit(1); // Exit the program on error
});

// Handle the connection closing
ws.on('close', function close() {
  console.log('Disconnected from the server.');
  process.exit(0); 
});

// Set up readline to listen for single keypresses
readline.emitKeypressEvents(process.stdin);
if (process.stdin.isTTY) {
    process.stdin.setRawMode(true);
}

// Radians
// 0 - EAST
// π/2 - SOUTH
// π - WEST
// 3π/2 - NORTH
var ship_theta = 0.0;

process.stdin.on('keypress', (str, key) => {
  if (key.ctrl && key.name === 'c') {
    ws.close();
  }

  if (ws.readyState === WebSocket.OPEN) {
    let message = '';
    
    if (key.name === 'j') {
      message = '{"theta": ' + ship_theta + '}';
    } else if (key.name === 'k') {
      message = '{"theta": ' + ship_theta + '}';
    } else if (key.name === 'space') {
      message = '{"fire":true}';
    }

    if (message) {
      console.log(`Sending: ${message}`);
      ws.send(message);
    }
  } else {
    console.log('WebSocket is not connected. Cannot send message.');
  }
});
