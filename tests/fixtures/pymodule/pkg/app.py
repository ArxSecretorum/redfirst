from pkg.engine import start
from pkg.radio import send


def run():
    return start()


def announce():
    return send("up")
