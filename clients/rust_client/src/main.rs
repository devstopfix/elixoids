use tokio_tungstenite::{connect_async, tungstenite::protocol::Message};
use futures_util::{StreamExt, SinkExt};
use url::Url;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 1. Define the WebSocket URL
    let url = Url::parse("ws://54.179.130.230/0/ship/JEV").expect("Invalid URL");

    // 2. Connect to the server
    println!("Connecting to {}...", url);
    let (ws_stream, _) = connect_async(url).await?;
    println!("WebSocket handshake successful.");

    // 3. Split the stream into a sender and a receiver
    let (mut write, mut read) = ws_stream.split();

    // 4. Send a message to get an echo back
    let send_message = "{}";
    write.send(Message::Text(send_message.to_string())).await?;
    println!("Sent: '{}'", send_message);

    // 5. Read the first incoming message
    if let Some(msg_result) = read.next().await {
        let msg = msg_result?;
        match msg {
            Message::Text(text) => {
                println!("Received: {}", text);
            },
            _ => {
                println!("Received non-text message: {:?}", msg);
            }
        }
    }

    Ok(())
}