import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'ConquerMaxChecker/ConquerAssetTool.py'


class ProcessLoggingTests(unittest.TestCase):
    def test_version_and_argument_error_keep_exit_codes_and_logs(self):
        with tempfile.TemporaryDirectory() as tmp:
            log = Path(tmp) / '中文 & 日志/run.log'
            for args, expected in [(['--version'], 0), (['invalid-command'], 2)]:
                result = subprocess.run(
                    [sys.executable, str(SCRIPT), '--log-file', str(log), *args],
                    capture_output=True, timeout=15)
                self.assertEqual(result.returncode, expected)
                self.assertEqual(result.stdout + result.stderr, b'')
                content = log.read_text(encoding='utf-8')
                self.assertIn('START ', content)
                self.assertIn(f'END exit={expected}', content)

    def test_large_report_does_not_require_parent_pipe_readers(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'asset'
            (root / 'MAX').mkdir(parents=True)
            (root / 'MAX' / 'asset.max').write_bytes(b'test scene placeholder')
            for i in range(400):
                (root / 'MAX' / f'missing-pair-{i}.tga').write_bytes(b'invalid')
            log = Path(tmp) / 'run.log'
            result = subprocess.run(
                [sys.executable, str(SCRIPT), '--log-file', str(log), 'check',
                 str(root), '--output', str(Path(tmp) / 'reports')],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
            self.assertEqual(result.returncode, 1)
            self.assertGreater(log.stat().st_size, 65536)
            self.assertIn('END exit=1', log.read_text(encoding='utf-8'))
