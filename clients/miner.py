#
# Shoots the Asteroid with the most constant bearing relative to us
#
#  -- https://en.wikipedia.org/wiki/Constant_bearing,_decreasing_range
#
# To run:
#
#     pip3 install websocket-client
#
#     python3 clients/miner.py --host localhost:8065 --game 0 --name ÅSA
#

from functools import partial
from math import floor, pi, atan
from random import choices, normalvariate
from string import ascii_uppercase
from time import sleep
import argparse
import datetime
import json
import sys
import urllib.parse
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


def angular_radius(distance, radius):
    return atan(radius / distance)

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
        return {rk: [theta, dist, radius] for [rk, theta, radius, dist] in state['rocks']}

    def saucer(self, state):
        src = next(filter(lambda x: x[0] == 'SČR', state['ships']), None)
        if src:
            return {-666: [src[1], src[2], 30.0]}
        else:
            return {}

    def targets(self, state):
        rocks = self.rocks(state)
        rocks.update(self.saucer(state))
        return rocks

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

    ANGULAR_SIZE = 0.01
    target_id = 0

    # Find the difference between thetas over successive game states
    # The dampen factor can be adjusted to stop switching targets too often
    def delta_theta(self, a, dampen=1.5):
        [_, s0, s1] = a
        [t0, _, _] = s0
        [t1, _, _] = s1
        return abs(t1 - t0) / dampen

    def sort_smallest_change_in_bearing(self, delta_state):
        return sorted(delta_state, key=lambda a: (self.delta_theta(a), a[0]) )

    def choose_target(self, delta_state):
        targets = self.sort_smallest_change_in_bearing(delta_state)
        return targets[0]

    def pointing_at(self, ship_theta, target):
        [target_theta, target_distance, target_radius] = target
        if target_distance > 0:
            angular_r = angular_radius(target_distance, target_radius)
            return abs(normalize(ship_theta) - normalize(target_theta)) < angular_r
        else:
            return False

    def lead_target(self, target):
        [_, s0, s1] = target
        [t0, _, _] = s0
        [t1, _, _] = s1
        return normalize(t1 + (t1 - t0))

    def strategy(self, delta_state, ship_theta):
        target = self.choose_target(delta_state)
        target_theta = self.lead_target(target)
        perturbed_theta = perturb(target_theta, self.ANGULAR_SIZE)
        if any(self.pointing_at(ship_theta, target[-1]) for target in delta_state):
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
        targets = miner.targets(state)
        if any(targets):
            ship_theta = state['theta']
            reply = miner.handle(targets, ship_theta)
            if reply:
                ws.send(json.dumps(reply))
    except:
        import traceback
        traceback.print_exc()
        sys.exit(1)


def on_error(ws, error):
    sys.stderr.write("\n{}\n\n".format(str(error)))


def on_close(ws, close_status_code, close_msg):
    sys.stderr.write("GAME OVER!\n")


def news_url(host, game, player_name="MIN"):
    return "ws://{}/{}/ship/{}".format(host, game, urllib.parse.quote(player_name))

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
