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

from functools import partial
from math import floor, pi
from random import choices, normalvariate
from string import ascii_uppercase
from time import sleep
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
        return [(k, v0, v1) for k, v0 in s0.items() for k1, v1 in s1.items() if k == k1]

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

    ANGULAR_SIZE = 0.05
    target_id = 0

    # Find the difference between thetas over successive game states
    # The dampen factor can be adjusted to stop switching targets too often
    def delta_theta(self, a, dampen=1.5):
        [_, s0, s1] = a
        [t0, _] = s0
        [t1, _] = s1
        return abs(t1 - t0) / dampen

    def sort_smallest_change_in_bearing(self, delta_state):
        return sorted(delta_state, key=lambda a: (self.delta_theta(a), a[0]) )

    def choose_target(self, delta_state):
        targets = self.sort_smallest_change_in_bearing(delta_state)
        return targets[0]

    def pointing_at(self, ship_theta, target_theta):
        return abs(normalize(ship_theta) - normalize(target_theta)) < self.ANGULAR_SIZE

    def lead_target(self, target):
        [_, s0, s1] = target
        [t0, _] = s0
        [t1, _] = s1
        return normalize(t1 + (t1 - t0))

    def strategy(self, delta_state, ship_theta):
        target = self.choose_target(delta_state)
        if (target[0] != self.target_id):
            self.target_id = target[0]
        target_theta = self.lead_target(target)
        perturbed_theta = perturb(target_theta, self.ANGULAR_SIZE)
        if self.pointing_at(ship_theta, target_theta):
            return {'theta': perturbed_theta, 'fire': True}
        else:
            return {'theta': perturbed_theta}


# Miner

# Generate a random name
def name():
    return 'M' + ''.join(''.join(choices(ascii_uppercase, k=2)))



def on_message(miner, ws, message):
    try:
        state = json.loads(message)
        rocks = miner.rocks(state)
        if rocks:
            ship_theta = state['theta']
            reply = miner.handle(rocks, ship_theta)
            if reply:
                ws.send(json.dumps(reply))
    except:
        import traceback
        traceback.print_exc()
        sys.exit(1)


def on_error(ws, error):
    sys.stderr.write("\n{}\n\n".format(str(error)))


def on_close(ws):
    sys.stderr.write("GAME OVER!\n")


def news_url(host, game, player_name="MIN"):
    return "ws://{}/{}/ship/{}".format(host, game, player_name)

# Runner


def options():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="localhost:8065",
                        help="host[:port] of Elixoids server")
    parser.add_argument("-n", "--name", default=None,
                        help="Three character name")
    parser.add_argument("--game", default=0,
                        help="Game id")
    return parser.parse_args()


def run(ws):
    retry = 5
    while retry > 0:
            ws.run_forever()
            sleep(retry)
            retry = retry - 1


if __name__ == "__main__":
    args = options()
    player_name = args.name or name()
    miner = ConstantBearingMiner(player_name)

    ws_url = news_url(args.host, args.game, player_name)
    ws = websocket.WebSocketApp(ws_url,
                                header={"Accept": "application/json"},
                                on_message=partial(on_message, miner),
                                on_error=on_error,
                                on_close=on_close)
    run(ws)
