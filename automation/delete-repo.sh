#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
STUDENT_ID="${1:-${STUDENT_ID:-}}"
REPO_KIND="${2:-all}"

# 可选参数（用于同时清理 workshop-events 中的学员记录）
EVENT_ID=""
JFROG_URL=""
JFROG_TOKEN=""
shift 2 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --event-id)   EVENT_ID="$2";   shift 2 ;;
    --jfrog-url)  JFROG_URL="${2%/}"; shift 2 ;;
    --token)      JFROG_TOKEN="$2"; shift 2 ;;
    *) shift ;;
  esac
done

normalize_student_id() {
  value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$value" in
    ""|*[!a-z0-9-]*)
      echo "Invalid student id: $1. Use 3-20 lowercase letters, numbers, and hyphens only. Examples: alex, mary-chen, john2." >&2
      exit 1
      ;;
  esac

  length="$(printf '%s' "$value" | wc -c | tr -d ' ')"
  if [ "$length" -lt 3 ] || [ "$length" -gt 20 ] || ! printf '%s' "$value" | grep -Eq '^[a-z0-9].*[a-z0-9]$'; then
    echo "Invalid student id: $1. Use 3-20 lowercase letters, numbers, and hyphens only. Examples: alex, mary-chen, john2." >&2
    exit 1
  fi

  printf '%s' "$value"
}

if [ -z "$STUDENT_ID" ]; then
  echo "Usage: $0 <student-id> [all|local|remote|virtual]" >&2
  echo "Example: $0 alex all" >&2
  exit 1
fi

STUDENT_ID="$(normalize_student_id "$STUDENT_ID")"

build_key_lines() {
  python3 - "$1" "$STUDENT_ID" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

prefix = sys.argv[2]

def student_repo_name(key):
    base = key
    if base.startswith("workshop-"):
        base = base[len("workshop-"):]
    return f"{prefix}-{base}"

for item in data:
    print(student_repo_name(item.get("key", "")))
PY
}

delete_repos() {
  values_file="$1"

  build_key_lines "$values_file" | while IFS= read -r repo_key; do
    [ -n "$repo_key" ] || continue
    jf rt repo-delete "$repo_key" --quiet
  done
}

delete_build_info() {
  build_name="${STUDENT_ID}-npm-sample"
  echo "Deleting build-info: $build_name"
  # build-discard/retention can't remove a whole build; use the Artifactory build deletion API.
  jf rt curl -XDELETE "/api/build/${build_name}?deleteAll=1&artifacts=0" \
    -H "Content-Type: application/json" || \
    echo "Build-info '$build_name' not found or already deleted; skipping." >&2
}

delete_workshop_records() {
  [ -n "$EVENT_ID" ] && [ -n "$JFROG_URL" ] && [ -n "$JFROG_TOKEN" ] || return 0
  echo "Deleting workshop records for ${STUDENT_ID} in event ${EVENT_ID}..."
  for f in profile.json progress.json; do
    curl -sf -X DELETE \
      -H "Authorization: Bearer ${JFROG_TOKEN}" \
      "${JFROG_URL}/artifactory/workshop-events/${EVENT_ID}/participants/${STUDENT_ID}/${f}" \
      >/dev/null 2>&1 || true
  done
  echo "Workshop records deleted."
}

case "$REPO_KIND" in
  all)
    delete_repos "$SCRIPT_DIR/virtual-repo-values.json"
    delete_repos "$SCRIPT_DIR/remote-repo-values.json"
    delete_repos "$SCRIPT_DIR/local-repo-values.json"
    delete_build_info
    delete_workshop_records
    ;;
  local)
    delete_repos "$SCRIPT_DIR/local-repo-values.json"
    ;;
  remote)
    delete_repos "$SCRIPT_DIR/remote-repo-values.json"
    ;;
  virtual)
    delete_repos "$SCRIPT_DIR/virtual-repo-values.json"
    ;;
  *)
    echo "Usage: $0 <student-id> [all|local|remote|virtual]" >&2
    exit 1
    ;;
esac
