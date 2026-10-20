#!/usr/bin/env python3
"""macOS와 Linux에서 자식 프로세스까지 종료하는 검증 명령 시간 제한."""
import os
import signal
import subprocess
import sys

process = subprocess.Popen(sys.argv[2:], start_new_session=True)
try:
    sys.exit(process.wait(timeout=int(sys.argv[1])))
except subprocess.TimeoutExpired:
    os.killpg(process.pid, signal.SIGTERM)
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
    print('검증 명령 시간 제한 초과', file=sys.stderr)
    sys.exit(124)
