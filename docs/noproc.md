
```
15:45:30.885 [error] Ranch listener :http had connection process started with :cowboy_protocol:start_link/4 at #PID<0.642.0> exit with reason: [reason: 
  {:noproc, {GenServer, :call, [:game, :state, 5000]}}, 


  mfa: {Elixoids.Server.WebsocketHandler, :websocket_info, 3}, stacktrace: [{GenServer, :call, 3, [file: 'lib/gen_server.ex', line: 596]}, 

  {Elixoids.Server.WebsocketHandler, :websocket_info, 3, 
  [file: 'lib/elixoids/server/websocket_handler.ex', line: 86]}, 

  {:cowboy_websocket, :handler_call, 7, 

  [file: 'src/cowboy_websocket.erl', line: 588]}, {:cowboy_protocol, :execute, 4, [file: 'src/cowboy_protocol.erl', line: 442]}], msg: {:timeout, #Reference<0.0.2.128813>, []}, req: [socket: #Port<0.6232>, transport: :ranch_tcp, connection: :keepalive, pid: #PID<0.642.0>, method: "GET", version: :"HTTP/1.1", peer: {{127, 0, 0, 1}, 55621}, host: "localhost", host_info: :undefined, port: 8065, path: "/websocket", path_info: :undefined, qs: "", qs_vals: :undefined, bindings: [], headers: [{"host", "localhost:8065"}, {"connection", "Upgrade"}, {"pragma", "no-cache"}, {"cache-control", "no-cache"}, {"upgrade", "websocket"}, {"origin", "http://localhost:8065"}, {"sec-websocket-version", "13"}, {"user-agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36"}, {"accept-encoding", "gzip, deflate, sdch"}, {"accept-language", "en-US,en;q=0.8"}, {"sec-websocket-key", "THQmLpMyyMvqcNzYJrax9Q=="}, {"sec-websocket-extensions", "permessage-deflate; client_max_window_bits"}], p_headers: [{"sec-websocket-extensions", [{"permessage-deflate", ["client_max_window_bits"]}]}, {"upgrade", ["websocket"]}, {"connection", ["upgrade"]}], cookies: :undefined, meta: [websocket_version: 13, websocket_compress: false], body_state: :waiting, buffer: "", multipart: :undefined, resp_compress: false, resp_state: :done, resp_headers: [], resp_body: "", onresponse: :undefined], state: %{a: [[71, 3029.2, 1997.1, 30.0], [72, 1108.4, 2074.9, 30.0], [74, 1667.6, 1718.9, 30.0], [91, 2032.0, 109.4, 60.0], [94, 2670.2, 1862.0, 15.0], [98, 666.4, 409.8, 30.0], [99, 3839.1, 1698.8, 30.0], [101, 541.1, 465.9, 15.0], [102, 3381.8, 1507.5, 15.0], [105, 1851.1, 345.8, 15.0], [106, 2913.5, 162.6, 15.0], [107, 3686.3, 1431.6, 15.0], [108, 3812.5, 1016.8, 15.0], [109, 1613.8, 116.4, 15.0]], b: [], dim: [4.0e3, 2250.0], kby: %{}, s: [["FIR", 1019.5, 576.7, 20.0, 0.0, "FFFFFF"]], x: []}]
```
