#
# cat the news stream of an Elixoids game
#
#
# To run:
#
#     pip3 install websocket-client
#
#     python3 clients/cat_news.py localhost:8065
#

import argparse
import sys
import websocket
try:
    import thread
except ImportError:
    import _thread as thread

def on_message(ws, message):
    print(message)

def on_error(ws, error):
    sys.stderr.write("{}\n\n".format(str(error)))

def on_close(ws):
    sys.stderr.write("### News closed\n")

def news_url(host):
    return "ws://{}/news".format(host)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("host", help="host[:port] of Elixoids server", default="localhost:8065")
    args = parser.parse_args()
    ws_url = news_url(args.host)
    ws = websocket.WebSocketApp(ws_url,
                              header = {"Accept": "text/plain"},
                              on_message = on_message,
                              on_error = on_error,
                              on_close = on_close)
    ws.run_forever()
