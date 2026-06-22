#!/bin/bash

set -eu

STUDENT_ID="${1:-${STUDENT_ID:-}}"

# 可选参数（用于同时清理 workshop-events 中的学员记录）
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

if [ -z "$JFROG_URL" ] || [ -z "$JFROG_TOKEN" ]; then
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
    echo "    不存在，跳过：${key}"
    return 0
  fi
  curl_jf -X DELETE "${API}/repositories/${key}" >/dev/null
  echo "    ✅ 已删除：${key}"
}

echo ">>> 删除 Artifactory 仓库..."
delete_repo "${STUDENT_ID}-npm-virtual"
delete_repo "${STUDENT_ID}-npm-remote"
delete_repo "${STUDENT_ID}-npm-dev-local"

echo ">>> 删除 build-info..."
curl_jf -X DELETE "${API}/build/${STUDENT_ID}-npm-sample?deleteAll=1&artifacts=0" \
  >/dev/null 2>&1 || echo "    build-info 不存在或已删除，跳过"

if [ -n "$EVENT_ID" ]; then
  echo ">>> 删除 workshop 记录..."
  for f in profile.json progress.json; do
    curl_jf -X DELETE \
      "${JFROG_URL}/artifactory/workshop-events/${EVENT_ID}/participants/${STUDENT_ID}/${f}" \
      >/dev/null 2>&1 || true
  done
  echo "    ✅ workshop 记录已删除"
fi

echo "✅ ${STUDENT_ID} 清理完成"
