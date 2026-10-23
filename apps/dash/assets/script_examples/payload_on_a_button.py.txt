"""Payload on a button.

Drops the payload when you press the button in dash, the D key, or the
controller's left trigger, and marks the spot on the recording.
"""
from koebelt_dash_scripts import connect

dev = connect()


@dev.trigger("Drop payload", key="D", gamepad="LT")
def drop():
    dev.cmd("release")
    x, y, z = dev.tlm.pos
    dev.mark(f"payload at {x:.1f}, {y:.1f} m")
    dev.notify("Payload dropped")


dev.run()
