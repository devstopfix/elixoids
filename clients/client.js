// Import the WebSocket library
const WebSocket = require('ws');
// Import the readline module to read keypresses
const readline = require('readline');

// --- Configuration ---
// Connect to a WebSocket server on the local machine.
// Replace '127.0.0.1' with your server's IP address if it's on your local network.
const SERVER_ADDRESS = 'ws://122.248.228.103/0/ship/JEV';

// --- WebSocket Connection ---
console.log(`Attempting to connect to ${SERVER_ADDRESS}`);
const ws = new WebSocket(SERVER_ADDRESS);

// --- Event Handlers ---

// Handle the connection opening
ws.on('open', function open() {
  console.log('Successfully connected to the server!');
  console.log('Press "j" for LEFT, "k" for RIGHT, SPACE for FIRE. Press CTRL+C to exit.');
});

// Handle incoming messages from the server
ws.on('message', function incoming(data) {
  console.log(`Received from server: ${data}`);
});

// Handle connection errors
ws.on('error', function error(err) {
  console.error('Connection Error:', err.message);
  console.error('Please make sure the WebSocket server is running.');
  process.exit(1); // Exit the program on error
});

// Handle the connection closing
ws.on('close', function close() {
  console.log('Disconnected from the server.');
  process.exit(0); // Exit the program cleanly
});

// --- Keypress Handling ---

// Set up readline to listen for single keypresses
readline.emitKeypressEvents(process.stdin);
if (process.stdin.isTTY) {
    process.stdin.setRawMode(true);
}

// Listen for the 'keypress' event
process.stdin.on('keypress', (str, key) => {
  // Exit the program if CTRL+C is pressed
  if (key.ctrl && key.name === 'c') {
    ws.close();
  }

  // Check if the connection is open before sending
  if (ws.readyState === WebSocket.OPEN) {
    let message = '';
    
    if (key.name === 'j') {
      message = '{}';
    } else if (key.name === 'k') {
      message = '{}';
    } else if (key.name === 'space') {
      message = '{"fire":true}';
    }

    // If a valid key was pressed, send the message
    if (message) {
      console.log(`Sending: ${message}`);
      ws.send(message);
    }
  } else {
    console.log('WebSocket is not connected. Cannot send message.');
  }
});
