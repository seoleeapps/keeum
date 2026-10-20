#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${KEEUM_E2E_OUT:-$repo_root/build/e2e}"
mkdir -p "$out"
args=(--headless)
capture_args=()
if [[ "${1:-}" == "--capture" ]]; then args=(); capture_args=(--capture); shift; fi
python3 "$repo_root/scripts/run_with_timeout.py" 900 \
  bash "$repo_root/scripts/run_godot_isolated.sh" e2e -- \
  "${args[@]}" --script res://tools/e2e/journey.gd -- --out "$out" "${capture_args[@]}" "$@" 2>&1 | tee "$out/run.log"
if grep -Eq '^(SCRIPT ERROR|ERROR):' "$out/run.log"; then exit 1; fi
python3 "$repo_root/tools/e2e/check_e2e_coverage.py" --inventory "$repo_root/docs/qa/feature-inventory.json" --journey "$out/journey.json"
