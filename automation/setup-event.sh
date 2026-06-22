#!/bin/bash
# 主办者运行：初始化赛事，创建 workshop-events 仓库并上传 config.json

set -eu

usage() {
  cat >&2 <<EOF
Usage: $0 <EVENT_ID> <EVENT_NAME> <JFROG_URL> <JFROG_TOKEN>

  EVENT_ID    赛事唯一标识，例如 2025-06-shanghai
  EVENT_NAME  赛事展示名称，例如 "JFrog Workshop Shanghai"
  JFROG_URL   JFrog 实例地址，例如 https://mycompany.jfrog.io
  JFROG_TOKEN 管理员 Access Token

Example:
  $0 2025-06-shanghai "JFrog Workshop Shanghai" https://mycompany.jfrog.io \$TOKEN
EOF
  exit 1
}

[ $# -ge 4 ] || usage

EVENT_ID="$1"
EVENT_NAME="$2"
JFROG_URL="${3%/}"
JFROG_TOKEN="$4"

EVENTS_REPO="workshop-events"
API="${JFROG_URL}/artifactory/api"

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

echo ""
echo "=========================================="
echo "  JFrog Workshop 赛事初始化"
echo "=========================================="
echo "  赛事 ID   : ${EVENT_ID}"
echo "  赛事名称  : ${EVENT_NAME}"
echo "  JFrog URL : ${JFROG_URL}"
echo ""

# ── 步骤 1：确保 workshop-events 仓库存在 ──────────────────────────────────
echo ">>> 检查 ${EVENTS_REPO} 仓库..."
STATUS=$(curl_jf -o /dev/null -w "%{http_code}" "${API}/repositories/${EVENTS_REPO}" 2>/dev/null || echo "000")

if [ "$STATUS" = "200" ]; then
  echo "    ✅ 仓库已存在，跳过创建"
else
  echo "    创建 Generic 仓库 ${EVENTS_REPO}..."
  curl_jf -X PUT "${API}/repositories/${EVENTS_REPO}" \
    -H "Content-Type: application/json" \
    -d '{
      "rclass": "local",
      "packageType": "generic",
      "description": "JFrog Workshop 赛事数据存储",
      "repoLayoutRef": "simple-default",
      "xrayIndex": false
    }'
  echo "    ✅ 仓库创建成功"
fi

# ── 步骤 2：生成并上传 config.json ─────────────────────────────────────────
echo ""
echo ">>> 生成 config.json..."

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
    { "id": "T1", "name": "注册昵称并创建个人仓库", "points": 10 },
    { "id": "T2", "name": "完成首次 npm build", "points": 20 },
    { "id": "T3", "name": "发布 Build #1 build-info", "points": 20 },
    { "id": "T4", "name": "创建 Curation Policy", "points": 20 },
    { "id": "T5", "name": "触发 Curation 阻断 axios@1.7.2", "points": 20 },
    { "id": "T6", "name": "修复并完成 Build #3", "points": 30 }
  ]
}
JSON
)

echo "$CONFIG_JSON" | curl_jf -X PUT \
  "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/config.json" \
  -H "Content-Type: application/json" \
  -T -
echo "    ✅ config.json 已上传"

# ── 完成 ────────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  ✅ 赛事初始化完成！"
echo "=========================================="
echo ""
echo "  下一步："
echo "  1. 运行以下命令启动实时排行榜（投屏此终端窗口）："
echo ""
echo "     bash automation/refresh-leaderboard.sh \\"
echo "       \"${EVENT_ID}\" \\"
echo "       \"${JFROG_URL}\" \\"
echo "       \"\$JFROG_TOKEN\""
echo ""
echo "  2. 将 EVENT_ID（${EVENT_ID}）和 JFROG_URL 告知学员"
echo ""
