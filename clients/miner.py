#
# Shoots the nearest asteroids - largest first
#
#
# To run:
#
#     pip3 install websocket-client
#
#     python3 clients/miner.py localhost:8065
#

import argparse
import sys
import websocket
try:
    import thread
except ImportError:
    import _thread as thread

from math import floor
import datetime
import json

def now():
    return floor(datetime.datetime.utcnow().timestamp() * 1000)

class Miner:
    prior_t = now()

    def elapsed(self):
        delta_t = now() - self.prior_t
        self.prior_t = now()
        return delta_t

    def rocks(self, state):
        return {rk: [theta, dist] for [rk, theta, radius, dist] in state['rocks']}


miner = Miner()

def on_message(ws, message):
    delta_t = miner.elapsed()
    print(delta_t)
    print(miner.rocks(json.loads(message)))

def on_error(ws, error):
    sys.stderr.write("{}\n\n".format(str(error)))

def on_close(ws):
    sys.stderr.write("### Miner closed\n")

def news_url(host):
    return "ws://{}/ship/{}".format(host, "MIN")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("host", help="host[:port] of Elixoids server", default="localhost:8065")
    args = parser.parse_args()
    ws_url = news_url(args.host)
    websocket.enableTrace(True)
    ws = websocket.WebSocketApp(ws_url,
                              on_message = on_message,
                              on_error = on_error,
                              on_close = on_close)
    ws.run_forever()
