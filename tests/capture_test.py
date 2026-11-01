import importlib.util
import os
import subprocess
import sys
import time
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('capture', Path(__file__).parents[1] / 'capture.py')
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)

class CaptureTests(unittest.TestCase):
    def pipe_run(self, data, **kwargs):
        r, w = os.pipe()
        if data is not None:
            os.write(w, data)
            os.close(w)
        try:
            with os.fdopen(r, 'rb') as stream:
                return capture.supervise(stream, **kwargs)
        finally:
            if data is None:
                os.close(w)

    def test_eof_releases(self):
        self.assertEqual(self.pipe_run(b''), 'stopped')

    def test_stop_releases(self):
        self.assertEqual(self.pipe_run(b'heartbeat\nstop\n'), 'stopped')

    def test_dead_ui_times_out(self):
        start = time.monotonic()
        self.assertEqual(self.pipe_run(None, heartbeat_timeout=0.03), 'heartbeat-timeout')
        self.assertLess(time.monotonic() - start, 1)

    def test_duration_limit(self):
        self.assertEqual(self.pipe_run(None, max_duration=0.03), 'session-limit')

    def test_hyprland_error_does_not_claim_ready(self):
        with patch.object(capture.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, 'Lua error', '')):
            with self.assertRaises(RuntimeError):
                capture.hypr_eval('invalid')

    def test_restore_is_scoped_and_never_executes_a_lesson(self):
        self.assertIn('hl.get_current_submap() == "omadojo-practice"', capture.CLEANUP)
        self.assertNotIn('window.close', capture.SETUP)
        self.assertNotIn('unbind("SUPER', capture.SETUP)

class WorkerLifecycleTests(unittest.TestCase):
    def test_killing_process_parent_still_runs_cleanup(self):
        import tempfile
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            fake = base / 'hyprctl'
            fake.write_text('#!/usr/bin/env python3\nimport os,sys\nwith open(os.environ["DOJO_TEST_LOG"],"a") as f: f.write("SETUP\\n" if "define_submap" in sys.argv[-1] else "CLEANUP\\n")\nprint("ok")\n')
            fake.chmod(0o755)
            log = base / 'calls'
            env = dict(os.environ, PATH=str(base) + os.pathsep + os.environ['PATH'], DOJO_TEST_LOG=str(log))
            process = subprocess.Popen([sys.executable, str(Path(__file__).parents[1] / 'capture.py')],
                                       stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
            try:
                import json
                self.assertTrue(json.loads(process.stdout.readline())['ready'])
                process.kill()
                process.wait(timeout=3)
                process.stdin.close()
                for _ in range(50):
                    if log.exists() and 'CLEANUP' in log.read_text():
                        break
                    time.sleep(0.02)
                self.assertEqual(log.read_text(), 'SETUP\nCLEANUP\n')
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=3)
                if not process.stdin.closed:
                    process.stdin.close()
                process.stdout.close()
                process.stderr.close()
