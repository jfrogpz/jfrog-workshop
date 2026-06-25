#!/bin/bash
# Organizer: delete all participants' repositories, build-info, and event records
# 主办者运行：删除所有学员的仓库、build-info 和赛事记录

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

usage() {
  cat >&2 <<EOF
Set environment variables first / 使用前请先设置环境变量：
  export JFROG_TOKEN="your-admin-token"
  export JFROG_URL="https://mycompany.jfrog.io"

Usage: $0 <EVENT_ID>

  EVENT_ID    Event ID to clean up / 要清理的赛事 ID，例如 2026-06-shanghai
EOF
  exit 1
}

[ $# -ge 1 ] || usage
EVENT_ID="$1"

if [ -z "${JFROG_TOKEN:-}" ] || [ -z "${JFROG_URL:-}" ]; then
  echo "❌ JFROG_TOKEN and JFROG_URL must be set" >&2
  exit 1
fi

JFROG_URL="${JFROG_URL%/}"
API="${JFROG_URL}/artifactory/api"
EVENTS_REPO="workshop-events"

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

echo ""
echo "=========================================="
echo "  Post-Event Cleanup / 赛后清理"
echo "  Event ID / 赛事 ID：${EVENT_ID}"
echo "=========================================="
echo ""

PARTICIPANTS=$(curl_jf \
  "${API}/storage/${EVENTS_REPO}/${EVENT_ID}/participants" 2>/dev/null \
  | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    names = [c['uri'].strip('/') for c in data.get('children', []) if c.get('folder')]
    print('\n'.join(names))
except:
    pass
" || echo "")

if [ -z "$PARTICIPANTS" ]; then
  echo "  No participants found for event / 未找到该赛事的学员：${EVENT_ID}"
  exit 0
fi

COUNT=$(echo "$PARTICIPANTS" | wc -l | tr -d ' ')
echo "  Found ${COUNT} participant(s) / 找到 ${COUNT} 名学员"
echo ""

while IFS= read -r nickname; do
  [ -n "$nickname" ] || continue
  echo ">>> Cleaning up / 清理学员：${nickname}"
  bash "${SCRIPT_DIR}/cleanup-participant.sh" "$nickname" --event-id "$EVENT_ID"
  echo ""
done <<EOF
$PARTICIPANTS
EOF

echo "=========================================="
echo "  ✅ All participants cleaned up!"
echo "  ✅ 所有学员数据已清理完成！"
echo "=========================================="
echo ""
echo "  Next: delete the event directory in Artifactory UI:"
echo "  下一步：在 Artifactory UI 中删除赛事目录："
echo "  workshop-events/${EVENT_ID}/"
echo ""
