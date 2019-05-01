#
# Visualize the audio of an Elixoids game:
#
#     pip3 install websocket-client
#     python3 clients/listen.py --host example.com
#

import argparse
import sys
import websocket
try:
    import thread
except ImportError:
    import _thread as thread

import sound_pb2


def on_message(ws, message):
    sound = sound_pb2.Sound()
    sound.ParseFromString(message)
    if (sound.noise == sound_pb2.Sound.FIRE):
        sys.stdout.write(".")
        sys.stdout.flush()
    elif (sound.noise == sound_pb2.Sound.EXPLOSION):
        sys.stdout.write("💥")
        sys.stdout.flush()


def on_error(ws, error):
    sys.stderr.write("{}\n\n".format(str(error)))


def sound_url(host, game_id):
    return "ws://{}/{}/sound".format(host, game_id)


def options():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="localhost:8065",
                        help="host[:port] of Elixoids server")
    parser.add_argument("--game", default=0,
                        help="Game id")
    return parser.parse_args()


if __name__ == "__main__":
    args = options()
    ws_url = sound_url(args.host, args.game)
    ws = websocket.WebSocketApp(ws_url,
                                header={"Accept": "application/octet-stream"},
                                on_message=on_message,
                                on_error=on_error)
    ws.run_forever()
