#!/usr/bin/env python3
"""Own a temporary Hyprland submap while receiving heartbeats on stdin.

EOF, a missed heartbeat, signals, and a maximum session duration all release it.
No Hyprland configuration is written. All actions are simulated by the QML UI.
"""
import json
import os
import selectors
import signal
import subprocess
import sys
import time

SUBMAP = 'omadojo-practice'
SETUP = '''
if _G.omadojo_capture then error("Omadojo is already capturing") end
if hl.get_current_submap() ~= "" and hl.get_current_submap() ~= "reset" then
  error("Exit your current Hyprland submap before starting practice")
end
_G.omadojo_capture = {}
hl.define_submap("omadojo-practice", function()
  _G.omadojo_capture.escape = hl.bind("CTRL + ALT + ESCAPE", function()
    hl.dispatch(hl.dsp.submap("reset"))
    hl.exec_cmd("omarchy-shell shell hide io.github.tkreek.omadojo")
  end, { description = "Exit Omadojo practice" })
end)
hl.dispatch(hl.dsp.submap("omadojo-practice"))
'''
CLEANUP = '''
if hl.get_current_submap() == "omadojo-practice" then
  hl.dispatch(hl.dsp.submap("reset"))
end
if _G.omadojo_capture then
  if _G.omadojo_capture.escape then _G.omadojo_capture.escape:unbind() end
  _G.omadojo_capture = nil
end
'''


def hypr_eval(code):
    result = subprocess.run(['hyprctl', 'eval', code], capture_output=True, text=True, timeout=3)
    if result.returncode != 0 or result.stdout.strip() != 'ok':
        raise RuntimeError((result.stderr or result.stdout).strip() or 'Hyprland rejected capture')


def supervise(stream, heartbeat_timeout=5, max_duration=600):
    selector = selectors.DefaultSelector()
    selector.register(stream, selectors.EVENT_READ)
    started = last = time.monotonic()
    try:
        while time.monotonic() - started < max_duration:
            if time.monotonic() - last > heartbeat_timeout:
                return 'heartbeat-timeout'
            if selector.select(0.25):
                data = os.read(stream.fileno(), 4096)
                if not data or b'stop\n' in data:
                    return 'stopped'
                last = time.monotonic()
        return 'session-limit'
    finally:
        selector.close()


def main():
    # QProcess may SIGKILL its immediate child on shell shutdown. Keep the
    # watchdog in a separate session: pipe EOF or heartbeat timeout still
    # restores input even when the QProcess child is killed without cleanup.
    if '--worker' not in sys.argv and '--restore' not in sys.argv:
        worker = subprocess.Popen([sys.executable, __file__, '--worker'],
                                  stdin=sys.stdin, stdout=sys.stdout, stderr=sys.stderr,
                                  start_new_session=True)
        return worker.wait()
    if '--restore' in sys.argv:
        hypr_eval(CLEANUP)
        return
    def stop(*_):
        raise SystemExit(0)
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    # Set only once this process owns capture, so a second invocation never
    # tears down the first session when it fails to start.
    owned = False
    try:
        hypr_eval(SETUP)
        owned = True
        print(json.dumps({'ready': True}), flush=True)
        supervise(sys.stdin.buffer)
    except Exception as error:
        print(json.dumps({'error': str(error)}), flush=True)
        return 1
    finally:
        if owned:
            try:
                hypr_eval(CLEANUP)
            except Exception as error:
                print('Omadojo restore: ' + str(error), file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main())
