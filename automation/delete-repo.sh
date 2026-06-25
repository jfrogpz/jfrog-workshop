#!/bin/bash
# Delete a participant's Artifactory repositories and optionally their event records
# 删除学员的 Artifactory 仓库，并可选地删除赛事记录

set -eu

STUDENT_ID="${1:-${STUDENT_ID:-}}"

EVENT_ID=""
JFROG_URL="${JFROG_URL:-}"
JFROG_TOKEN="${JFROG_TOKEN:-}"
shift 1 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --event-id)   EVENT_ID="$2";   shift 2 ;;
    --jfrog-url)  JFROG_URL="${2%/}"; shift 2 ;;
    --token)      JFROG_TOKEN="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[ -n "$JFROG_URL" ] && JFROG_URL="${JFROG_URL%/}"

if [ -z "$STUDENT_ID" ]; then
  echo "Usage: $0 <student-id> [--event-id <id>]" >&2
  exit 1
fi

# Auto-load saved credentials if not already in environment
# 如果环境变量未设置，自动从本地 profile 加载
if [ -z "$JFROG_URL" ] || [ -z "$JFROG_TOKEN" ]; then
  PROFILE_FILE="${HOME}/.workshop-profile"
  # shellcheck disable=SC1090
  [ -f "$PROFILE_FILE" ] && . "$PROFILE_FILE" || true
  JFROG_URL="${JFROG_URL:-}"
  JFROG_TOKEN="${JFROG_TOKEN:-}"
fi

if [ -z "$JFROG_URL" ] || [ -z "$JFROG_TOKEN" ]; then
  echo "❌ JFROG_URL and JFROG_TOKEN environment variables must be set" >&2
  echo "❌ 需要设置 JFROG_URL 和 JFROG_TOKEN 环境变量" >&2
  exit 1
fi

API="${JFROG_URL}/artifactory/api"

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

delete_repo() {
  local key="$1"
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" "${API}/repositories/${key}" 2>/dev/null || echo "000")
  if [ "$s" != "200" ]; then
    echo "    Not found, skipping / 不存在，跳过：${key}"
    return 0
  fi
  curl_jf -X DELETE "${API}/repositories/${key}" >/dev/null
  echo "    ✅ Deleted / 已删除：${key}"
}

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"

echo ">>> Deleting Artifactory repositories / 删除 Artifactory 仓库..."
# Discover all repos to delete by running each module's create-repo.sh in dry-run mode.
# Fallback: list all repos matching the student ID prefix.
REPOS=$(curl_jf "${API}/repositories?type=local&packageType=&includeDescription=0" 2>/dev/null \
  | python3 -c "
import sys, json
repos = json.load(sys.stdin)
prefix = '${STUDENT_ID}-'
for r in repos:
    if r.get('key','').startswith(prefix):
        print(r['key'])
" 2>/dev/null || echo "")

if [ -n "$REPOS" ]; then
  while IFS= read -r repo; do
    [ -n "$repo" ] && delete_repo "$repo"
  done <<EOF
$REPOS
EOF
else
  echo "    No repositories found for ${STUDENT_ID} / 未找到 ${STUDENT_ID} 的仓库"
fi

echo ">>> Deleting build-info / 删除 build-info..."
# Delete all build-info entries matching the student ID prefix
BUILD_NAMES=$(curl_jf "${API}/build" 2>/dev/null \
  | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    builds = d.get('builds', [])
    prefix = '${STUDENT_ID}-'
    for b in builds:
        name = b.get('uri','').strip('/')
        if name.startswith(prefix):
            print(name)
except: pass
" 2>/dev/null || echo "")

if [ -n "$BUILD_NAMES" ]; then
  while IFS= read -r bname; do
    [ -n "$bname" ] || continue
    curl_jf -X DELETE "${API}/build/${bname}?deleteAll=1&artifacts=0" \
      >/dev/null 2>&1 && echo "    ✅ build-info deleted / 已删除：${bname}" \
      || echo "    build-info not found / 不存在：${bname}"
  done <<EOF
$BUILD_NAMES
EOF
else
  echo "    No build-info found for ${STUDENT_ID} / 未找到 ${STUDENT_ID} 的 build-info"
fi

if [ -n "$EVENT_ID" ]; then
  echo ">>> Deleting workshop records / 删除 workshop 记录..."
  for f in profile.json progress.json; do
    curl_jf -X DELETE \
      "${JFROG_URL}/artifactory/workshop-events/${EVENT_ID}/participants/${STUDENT_ID}/${f}" \
      >/dev/null 2>&1 || true
  done
  echo "    ✅ Workshop records deleted / workshop 记录已删除"
fi

echo "✅ ${STUDENT_ID} cleanup complete / 清理完成"
