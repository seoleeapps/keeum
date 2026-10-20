#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run_godot_isolated.sh LABEL [--without-marker] [--protect-fixtures|--expect-quarantine] -- GODOT_ARGS...
  run_godot_isolated.sh --print-real-user-dir PROJECT_NAME

Runs Godot with a disposable user:// directory without overriding HOME.
USAGE
}

host_user_home() {
  case "$(uname -s)" in
    Darwin)
      id -P "$(id -un)" | awk -F: '{print $9}'
      ;;
    Linux)
      getent passwd "$(id -u)" | awk -F: '{print $6}'
      ;;
    *)
      return 1
      ;;
  esac
}

host_user_data_dir() {
  local project_name="$1"
  local user_home_dir
  user_home_dir="$(host_user_home)" || return 1
  [[ -n "$user_home_dir" ]] || return 1

  case "$(uname -s)" in
    Darwin)
      printf '%s\n' "$user_home_dir/Library/Application Support/Godot/app_userdata/$project_name"
      ;;
    Linux)
      local data_root="${XDG_DATA_HOME:-$user_home_dir/.local/share}"
      printf '%s\n' "$data_root/godot/app_userdata/$project_name"
      ;;
  esac
}

if [[ "${1:-}" == "--print-real-user-dir" ]]; then
  [[ "$#" -eq 2 ]] || { usage >&2; exit 2; }
  host_user_data_dir "$2" || { echo "user:// 경로를 계산하지 못했다" >&2; exit 1; }
  exit 0
fi

[[ "$#" -ge 3 ]] || { usage >&2; exit 2; }

label="$1"
shift
with_marker=1
fixture_mode="none"

while [[ "$#" -gt 0 && "$1" != "--" ]]; do
  case "$1" in
    --without-marker)
      with_marker=0
      ;;
    --protect-fixtures)
      fixture_mode="protected"
      ;;
    --expect-quarantine)
      fixture_mode="corrupt"
      ;;
    *)
      echo "알 수 없는 옵션: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

[[ "${1:-}" == "--" ]] || { usage >&2; exit 2; }
shift
[[ "$#" -gt 0 ]] || { usage >&2; exit 2; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
isolation_cache_dir="${KEEUM_ISOLATION_CACHE_DIR:-}"
original_project_name="$(sed -nE 's/^config\/name="(.*)"$/\1/p' "$repo_root/project.godot" | head -n1)"
[[ -n "$original_project_name" ]] || { echo "project.godot에서 config/name을 읽지 못했다" >&2; exit 1; }

run_root="$(mktemp -d "${TMPDIR:-/tmp}/keeum-isolated-run.XXXXXX")"
project_root="$repo_root"
isolated_project_name="$original_project_name"
isolated_user_dir=""
user_home_dir=""

# shellcheck disable=SC2329 # trap에서 호출한다.
cleanup() {
  if [[ "$(uname -s)" == "Darwin" && -n "$isolated_user_dir" && -n "$user_home_dir" \
      && "$isolated_user_dir" == "$user_home_dir/Library/Application Support/Godot/app_userdata/keeum-test-"* ]]; then
    rm -rf -- "$isolated_user_dir"
  fi
  if [[ -n "$run_root" && "$run_root" == "${TMPDIR:-/tmp}/keeum-isolated-run."* ]]; then
    rm -rf -- "$run_root"
  fi
}
trap cleanup EXIT

xdg_data_home=""
case "$(uname -s)" in
  Darwin)
    user_home_dir="$(host_user_home)"
    [[ -n "$user_home_dir" ]] || { echo "macOS 사용자 홈을 확인하지 못했다" >&2; exit 1; }
    isolated_project_name="keeum-test-${label//[^A-Za-z0-9_-]/-}-$(basename "$run_root")"
    project_root="$run_root/project"
    mkdir -p "$project_root"
    awk -v name="$isolated_project_name" '
      /^config\/name=/ { print "config/name=\"" name "\""; next }
      { print }
    ' "$repo_root/project.godot" > "$project_root/project.godot"
    for source_dir in addons assets core data game tools; do
      if ! cp -cR "$repo_root/$source_dir" "$project_root/$source_dir" 2>/dev/null; then
        rm -rf -- "${project_root:?}/$source_dir"
        cp -R "$repo_root/$source_dir" "$project_root/$source_dir"
      fi
    done
    isolated_user_dir="$user_home_dir/Library/Application Support/Godot/app_userdata/$isolated_project_name"
    ;;
  Linux)
    isolated_user_dir="$run_root/godot/app_userdata/$isolated_project_name"
    xdg_data_home="$run_root"
    ;;
  *)
    echo "지원하지 않는 플랫폼: $(uname -s)" >&2
    exit 1
    ;;
esac

mkdir -p "$isolated_user_dir"

godot_args=()
while [[ "$#" -gt 0 ]]; do
  if [[ "$1" == "--path" ]]; then
    [[ "$#" -ge 2 ]] || { echo "--path 값이 없다" >&2; exit 2; }
    shift 2
    continue
  fi
  godot_args+=("$1")
  shift
done

run_godot() {
  if [[ "$with_marker" -eq 1 && -n "$xdg_data_home" ]]; then
    env XDG_DATA_HOME="$xdg_data_home" KEEUM_TEST_USER_DIR="$isolated_user_dir" "$@"
  elif [[ "$with_marker" -eq 1 ]]; then
    env KEEUM_TEST_USER_DIR="$isolated_user_dir" "$@"
  elif [[ -n "$xdg_data_home" ]]; then
    env -u KEEUM_TEST_USER_DIR XDG_DATA_HOME="$xdg_data_home" "$@"
  else
    env -u KEEUM_TEST_USER_DIR "$@"
  fi
}

# 캐시는 동일한 소스와 리소스 집합에서만 재사용한다.
source_key="$(python3 - "$repo_root" "$("$godot_bin" --version)" <<'PYKEY'
import hashlib, sys
from pathlib import Path
root = Path(sys.argv[1]); digest = hashlib.sha256(b'keeum-import-cache-v2\0')
digest.update(sys.argv[2].encode())
for folder in ['core', 'game', 'tools', 'addons', 'data', 'assets']:
    for path in sorted((root / folder).rglob('*')):
        # .gdignore 아래 원본은 게임에서 임포트하지 않는다.
        ignored = any((parent / '.gdignore').exists() for parent in path.parents if parent != root and root in parent.parents)
        if path.is_file() and not ignored and path.suffix in [
            '.gd', '.uid', '.tscn', '.tres', '.json', '.ttf', '.otf', '.png',
            '.svg', '.webp', '.ogg', '.wav', '.mp3', '.gdextension', '.gdap'
        ]:
            digest.update(str(path.relative_to(root)).encode()); digest.update(path.read_bytes())
digest.update((root / 'project.godot').read_bytes())
print(digest.hexdigest())
PYKEY
)"
# 새 macOS 프로젝트 이름에는 Godot의 전역 클래스 캐시가 없다. 같은 상위 검증
# 실행에서는 최초 임포트 결과를 복사해 쓰되, 각 Godot 프로세스의 .godot 디렉터리와
# user://는 계속 분리한다. 픽스처는 준비가 끝난 뒤에 만들므로 임포트가 건드릴 수 없다.
cache_entry="${isolation_cache_dir:+$isolation_cache_dir/$source_key}"
if [[ "$(uname -s)" == "Darwin" && -n "$cache_entry" \
    && -f "$cache_entry/complete" \
    && -f "$cache_entry/.godot/global_script_class_cache.cfg" \
    && -d "$cache_entry/resource-remaps" ]]; then
  cp -R "$cache_entry/.godot" "$project_root/.godot"
  cp -R "$cache_entry/resource-remaps/." "$project_root/"
  printf 'KEEUM_IMPORT_CACHE=hit:%s\n' "$source_key"
elif [[ ! -f "$project_root/.godot/global_script_class_cache.cfg" ]]; then
  printf 'KEEUM_IMPORT_CACHE=miss:%s\n' "$source_key"
  set +e
  run_godot "$godot_bin" --headless --path "$project_root" --import --quit \
    > "$run_root/import.log" 2>&1
  import_exit=$?
  set -e
  if [[ "$import_exit" -ne 0 ]] || grep -Eq '^(SCRIPT ERROR|ERROR):' "$run_root/import.log"; then
    cat "$run_root/import.log" >&2
    echo "격리 프로젝트 임포트가 실패했다" >&2
    exit 96
  fi
  if [[ "$(uname -s)" == "Darwin" && -n "$isolation_cache_dir" ]]; then
    # 완성된 캐시만 공개한다. 동시 실행도 작성 중인 디렉터리를 읽지 않는다.
    python3 - "$project_root" "$cache_entry" <<'PYCACHE'
import errno, os, shutil, sys, tempfile
from pathlib import Path
project, entry = map(Path, sys.argv[1:])
entry.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='.keeum-cache-', dir=entry.parent) as temporary:
    staged = Path(temporary) / 'entry'
    shutil.copytree(project / '.godot', staged / '.godot')
    remaps = staged / 'resource-remaps'
    remaps.mkdir()
    for folder in ['addons', 'assets', 'core', 'data', 'game', 'tools']:
        for source in (project / folder).rglob('*.import'):
            destination = remaps / source.relative_to(project)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
    (staged / 'complete').write_text('2\n')
    try:
        os.rename(staged, entry)
    except OSError as error:
        if error.errno not in (errno.EEXIST, errno.ENOTEMPTY) or not (
            (entry / 'complete').is_file()
            and (entry / '.godot/global_script_class_cache.cfg').is_file()
            and (entry / 'resource-remaps').is_dir()
        ):
            raise
PYCACHE
  fi
fi

fixture_shas=""
if [[ "$fixture_mode" == "protected" ]]; then
  printf '%s' '{"profile":{"premium":791},"run":{}}' > "$isolated_user_dir/keeum_save.json"
  printf '%s' '{"profile":{"premium":555},"run":{}}' > "$isolated_user_dir/keeum_save.json.bak"
  printf '%s' 'corrupt sentinel' > "$isolated_user_dir/keeum_save.json.corrupt"
  fixture_shas="$(cd "$isolated_user_dir" && shasum -a 256 keeum_save.json keeum_save.json.bak keeum_save.json.corrupt)"
elif [[ "$fixture_mode" == "corrupt" ]]; then
  printf '%s' 'plain-run corrupt fixture' > "$isolated_user_dir/keeum_save.json"
fi

printf 'KEEUM_ISOLATED_USER_DIR=%s\n' "$isolated_user_dir"
set +e
run_godot "$godot_bin" --path "$project_root" "${godot_args[@]}"
godot_exit=$?
set -e

if [[ "$fixture_mode" == "protected" ]]; then
  set +e
  fixtures_after="$(cd "$isolated_user_dir" && shasum -a 256 keeum_save.json keeum_save.json.bak keeum_save.json.corrupt)"
  fixture_exit=$?
  set -e
  if [[ "$fixture_exit" -ne 0 || "$fixtures_after" != "$fixture_shas" ]]; then
    echo "격리 없는 실행이 보호 픽스처를 변경했다" >&2
    exit 97
  fi
  echo "KEEUM_PROTECTED_FIXTURES_UNTOUCHED=1"
elif [[ "$fixture_mode" == "corrupt" ]]; then
  if [[ -e "$isolated_user_dir/keeum_save.json" || ! -f "$isolated_user_dir/keeum_save.json.corrupt" ]]; then
    echo "평범한 실행이 기존 손상 격리 동작을 수행하지 않았다" >&2
    exit 98
  fi
  echo "KEEUM_CORRUPT_QUARANTINED=1"
fi

exit "$godot_exit"
