#!/usr/bin/env bash
set -euo pipefail
: "${AAB_PATH:?AAB_PATH가 필요합니다}"
python3 scripts/validate_android_aab.py "$AAB_PATH"
