#!/bin/bash
# Organizer: initialize an event, create the workshop-events repository and upload config.json
# 主办者运行：初始化赛事，创建 workshop-events 仓库并上传 config.json

set -eu

usage() {
  cat >&2 <<EOF
Set environment variables first / 使用前请先设置环境变量：
  export JFROG_TOKEN="your-admin-token"
  export JFROG_URL="https://mycompany.jfrog.io"

Usage: $0 <EVENT_ID> <EVENT_NAME>

  EVENT_ID    Unique event identifier / 赛事唯一标识，例如 2026-06-shanghai
  EVENT_NAME  Display name for the event / 赛事展示名称，例如 "JFrog Workshop Shanghai"

Example:
  export JFROG_TOKEN="your-admin-token"
  export JFROG_URL="https://mycompany.jfrog.io"
  $0 2026-06-shanghai "JFrog Workshop Shanghai"
EOF
  exit 1
}

[ $# -ge 2 ] || usage

EVENT_ID="$1"
EVENT_NAME="$2"

if [ -z "${JFROG_TOKEN:-}" ]; then
  echo "❌ JFROG_TOKEN environment variable is not set. Please run:" >&2
  echo "❌ 未设置 JFROG_TOKEN 环境变量，请先运行：" >&2
  echo "   export JFROG_TOKEN=\"your-admin-token\"" >&2
  exit 1
fi

if [ -z "${JFROG_URL:-}" ]; then
  echo "❌ JFROG_URL environment variable is not set. Please run:" >&2
  echo "❌ 未设置 JFROG_URL 环境变量，请先运行：" >&2
  echo "   export JFROG_URL=\"https://mycompany.jfrog.io\"" >&2
  exit 1
fi

JFROG_URL="${JFROG_URL%/}"

EVENTS_REPO="workshop-events"
API="${JFROG_URL}/artifactory/api"

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

echo ""
echo "=========================================="
echo "  JFrog Workshop Event Initialization"
echo "  JFrog Workshop 赛事初始化"
echo "=========================================="
echo "  Event ID / 赛事 ID   : ${EVENT_ID}"
echo "  Event Name / 赛事名称 : ${EVENT_NAME}"
echo "  JFrog URL             : ${JFROG_URL}"
echo ""

# ── Step 1: ensure the workshop-events repository exists ──────────────────────
echo ">>> Checking ${EVENTS_REPO} repository / 检查 ${EVENTS_REPO} 仓库..."
STATUS=$(curl_jf -o /dev/null -w "%{http_code}" "${API}/repositories/${EVENTS_REPO}" 2>/dev/null || echo "000")

if [ "$STATUS" = "200" ]; then
  echo "    ✅ Repository already exists, skipping / 仓库已存在，跳过创建"
else
  echo "    Creating Generic repository / 创建 Generic 仓库 ${EVENTS_REPO}..."
  curl_jf -X PUT "${API}/repositories/${EVENTS_REPO}" \
    -H "Content-Type: application/json" \
    -d '{
      "rclass": "local",
      "packageType": "generic",
      "description": "JFrog Workshop event data store",
      "repoLayoutRef": "simple-default",
      "xrayIndex": false
    }'
  echo "    ✅ Repository created / 仓库创建成功"
fi

# ── Step 2: generate and upload config.json ───────────────────────────────────
echo ""
echo ">>> Generating config.json / 生成 config.json..."

START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S+00:00")
END_TIME=$(date -u -d "+3 hours" +"%Y-%m-%dT%H:%M:%S+00:00" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S+00:00")

CONFIG_JSON=$(cat <<JSON
{
  "event_id": "${EVENT_ID}",
  "event_name": "${EVENT_NAME}",
  "jfrog_url": "${JFROG_URL}",
  "start_time": "${START_TIME}",
  "end_time": "${END_TIME}",
  "tasks": [
    { "id": "T1", "name": "Register nickname and create personal repositories", "points": 10 },
    { "id": "T2", "name": "Complete first npm build", "points": 20 },
    { "id": "T3", "name": "Publish Build #1 build-info", "points": 20 },
    { "id": "T4", "name": "Create Curation Policy", "points": 10 },
    { "id": "T5", "name": "Trigger Curation to block axios@1.7.2", "points": 20 },
    { "id": "T6", "name": "Fix and complete Build #3", "points": 20 }
  ]
}
JSON
)

echo "$CONFIG_JSON" | curl_jf -X PUT \
  "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/config.json" \
  -H "Content-Type: application/json" \
  -T -
echo "    ✅ config.json uploaded / config.json 已上传"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  ✅ Event initialization complete!"
echo "  ✅ 赛事初始化完成！"
echo "=========================================="
echo ""
echo "  Next steps / 下一步："
echo "  1. Start the leaderboard (project this terminal window) / 运行以下命令启动实时排行榜（投屏此终端窗口）："
echo ""
echo "     bash automation/refresh-leaderboard.sh \"${EVENT_ID}\""
echo ""
echo "  2. Share EVENT_ID (${EVENT_ID}) and JFROG_URL (${JFROG_URL}) with participants"
echo "     将 EVENT_ID（${EVENT_ID}）和 JFROG_URL（${JFROG_URL}）告知学员"
echo ""
