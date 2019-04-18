#
# Shoots the Asteroid with the most constant bearing relative to us
#
#  -- https://en.wikipedia.org/wiki/Constant_bearing,_decreasing_range
#
# To run:
#
#     pip3 install websocket-client
#
#     python3 clients/miner.py --host localhost:8065
#

from math import floor, pi
from random import choices, normalvariate
from string import ascii_uppercase
import argparse
import datetime
import json
import sys
import websocket
try:
    import thread
except ImportError:
    import _thread as thread


# Angles

def normalize(r):
    return r % (pi * 2)

def perturb(r, sigma=0.1):
    return normalize(r + normalvariate(0, sigma))

# Time

def now():
    return floor(datetime.datetime.utcnow().timestamp() * 1000)

# Base class

class Miner:

    def __init__(self, name):
        self.name = name
        self.prior_t = now()
        self.prior_state = {}

    def elapsed(self):
        delta_t = now() - self.prior_t
        self.prior_t = now()
        return delta_t

    # Difference between two states - map of id => [state-1, state]
    def delta(self, s0, s1):
        return [ (k,v0,v1) for k, v0 in s0.items() for k1,v1 in s1.items() if k==k1 ]

    def rocks(self, state):
        return {rk: [theta, dist] for [rk, theta, radius, dist] in state['rocks']}

    def handle(self, state, ship_theta):
        self.elapsed()
        delta_state = self.delta(self.prior_state, state)
        self.prior_state = state
        if delta_state:
            return self.strategy(delta_state, ship_theta)
        else:
            return {}

    # Subclasses should implement a strategy
    # Return {theta: radians , fire: True|False}
    def strategy(self, _delta_state, _ship_theta):
        return {}


class ConstantBearingMiner(Miner):

    ANGULAR_SIZE=0.1
    target_id = 0

    # Find the difference between thetas over successive game states
    # The dampen factor can be adjusted to stop switching targets too often
    def delta_theta(self, a, dampen=1.1):
        [_, s0, s1] = a
        [t0, _] = s0
        [t1, _] = s1
        return abs(t1 - t0) / dampen

    def sort_smallest_change_in_bearing(self, delta_state):
        return sorted(delta_state, key= lambda a: self.delta_theta(a))

    def choose_target(self, delta_state):
        targets = self.sort_smallest_change_in_bearing(delta_state)
        return targets[0]

    def pointing_at(self, ship_theta, target_theta):
        return abs(normalize(ship_theta) - normalize(target_theta)) < self.ANGULAR_SIZE

    def strategy(self, delta_state, ship_theta):
        target = self.choose_target(delta_state)
        if (target[0] != self.target_id):
            self.target_id = target[0]
            print("{} Switching target {}".format(self.name, self.target_id))
        target_theta = target[2][0]
        perturbed_theta = perturb(target_theta, self.ANGULAR_SIZE)
        if self.pointing_at(ship_theta, target_theta):
            return {'theta': perturbed_theta, 'fire': True}
        else:
            return {'theta': perturbed_theta}


# Miner

# Generate a random name
def name():
    return 'M' + ''.join(''.join(choices(ascii_uppercase, k=2)))


miner = ConstantBearingMiner(name())

def on_message(ws, message):
    state = json.loads(message)
    ship_theta = state['theta']
    rocks = miner.rocks(state)
    if rocks:
        reply = miner.handle(rocks, ship_theta)
        if reply:
            ws.send(json.dumps(reply))

def on_error(ws, error):
    sys.stderr.write("\n{}\n\n".format(str(error)))

def on_close(ws):
    sys.stderr.write("### Miner closed\n")

def news_url(host, player_name="MIN"):
    return "ws://{}/ship/{}".format(host, player_name)

# Runner

def options():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="localhost:8065", help="host[:port] of Elixoids server")
    parser.add_argument("-n", "--name", default=None, help="Three character name")
    return parser.parse_args()


if __name__ == "__main__":
    args = options()
    player_name = args.name or miner.name
    ws_url = news_url(args.host, player_name)
    ws = websocket.WebSocketApp(ws_url,
                              on_message = on_message,
                              on_error = on_error,
                              on_close = on_close)
    ws.run_forever()


#def sort_by_distance(self, delta_state):
   #return sorted(delta_state, key= lambda a: a[2][1])

#random.choice([True, False])
