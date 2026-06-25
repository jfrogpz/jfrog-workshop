#!/bin/bash
# Organizer: initialize an event, create the workshop-events repository and upload config.json
# 主办者运行：初始化赛事，创建 workshop-events 仓库并上传 config.json

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat >&2 <<EOF
Set environment variables first / 使用前请先设置环境变量：
  export JFROG_TOKEN="your-admin-token"
  export JFROG_URL="https://mycompany.jfrog.io"

Usage: $0 <EVENT_ID> <EVENT_NAME> --modules <module1>[,module2,...]

  EVENT_ID    Unique event identifier / 赛事唯一标识，例如 2026-06-shanghai
  EVENT_NAME  Display name for the event / 赛事展示名称，例如 "JFrog Workshop Shanghai"
  --modules   Comma-separated list of modules to include / 逗号分隔的模块列表

Available modules / 可用模块：
$(find "${REPO_ROOT}/modules" -name "tasks.json" 2>/dev/null \
  | sed "s|${REPO_ROOT}/modules/||;s|/tasks.json||" \
  | sort | sed 's/^/  - /' || echo "  (none found / 未找到任何模块)")

Examples / 示例：
  $0 2026-06-shanghai "JFrog Workshop Shanghai" --modules npm-security
  $0 2026-06-shanghai "JFrog Workshop Shanghai" --modules npm-security,maven-basic
EOF
  exit 1
}

# ── Parse arguments ────────────────────────────────────────────────────────────
[ $# -ge 2 ] || usage

EVENT_ID="$1"
EVENT_NAME="$2"
shift 2

MODULES_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --modules)
      MODULES_ARG="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1" >&2
      usage
      ;;
  esac
done

if [ -z "$MODULES_ARG" ]; then
  echo "❌ --modules is required / 必须指定 --modules 参数" >&2
  usage
fi

# ── Validate env vars ──────────────────────────────────────────────────────────
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

# ── Validate modules and collect tasks ────────────────────────────────────────
echo ""
echo "=========================================="
echo "  JFrog Workshop Event Initialization"
echo "  JFrog Workshop 赛事初始化"
echo "=========================================="
echo "  Event ID / 赛事 ID   : ${EVENT_ID}"
echo "  Event Name / 赛事名称 : ${EVENT_NAME}"
echo "  JFrog URL             : ${JFROG_URL}"
echo "  Modules / 模块        : ${MODULES_ARG}"
echo ""

echo ">>> Validating modules / 验证模块..."
# Convert comma-separated to space-separated for iteration
MODULES_LIST=$(echo "$MODULES_ARG" | tr ',' ' ')
TASKS_JSON_ARRAY=""

for MODULE in $MODULES_LIST; do
  TASKS_FILE="${REPO_ROOT}/modules/${MODULE}/tasks.json"
  if [ ! -f "$TASKS_FILE" ]; then
    echo "  ❌ Module not found: ${MODULE}" >&2
    echo "  ❌ 找不到模块：${MODULE}（缺少 modules/${MODULE}/tasks.json）" >&2
    exit 1
  fi
  TASK_COUNT=$(python3 -c "import json; d=json.load(open('${TASKS_FILE}')); print(len(d))" 2>/dev/null || echo "0")
  echo "    ✅ ${MODULE} (${TASK_COUNT} tasks / 个任务)"

  # Accumulate tasks JSON array entries
  MODULE_TASKS=$(python3 -c "
import json
tasks = json.load(open('${TASKS_FILE}'))
for t in tasks:
    print(json.dumps({'id': t['id'], 'name': t['name'], 'points': t['points']}))
" 2>/dev/null)
  if [ -n "$TASKS_JSON_ARRAY" ]; then
    TASKS_JSON_ARRAY="${TASKS_JSON_ARRAY}
${MODULE_TASKS}"
  else
    TASKS_JSON_ARRAY="${MODULE_TASKS}"
  fi
done

# Build tasks JSON array
TASKS_JSON=$(echo "$TASKS_JSON_ARRAY" | python3 -c "
import sys, json
lines = [l.strip() for l in sys.stdin if l.strip()]
tasks = [json.loads(l) for l in lines]
print(json.dumps(tasks, ensure_ascii=False, indent=2))
")

# ── Step 1: ensure the workshop-events repository exists ──────────────────────
echo ""
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

CONFIG_JSON=$(python3 -c "
import json, sys
config = {
    'event_id': '${EVENT_ID}',
    'event_name': '${EVENT_NAME}',
    'jfrog_url': '${JFROG_URL}',
    'start_time': '${START_TIME}',
    'end_time': '${END_TIME}',
    'modules': '${MODULES_ARG}'.split(','),
    'tasks': ${TASKS_JSON}
}
print(json.dumps(config, ensure_ascii=False, indent=2))
")

echo "$CONFIG_JSON" | curl_jf -X PUT \
  "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/config.json" \
  -H "Content-Type: application/json" \
  -T -
echo "    ✅ config.json uploaded / config.json 已上传"

# ── Done ──────────────────────────────────────────────────────────────────────
TOTAL_POINTS=$(echo "$TASKS_JSON" | python3 -c "
import sys, json
tasks = json.load(sys.stdin)
print(sum(t.get('points', 0) for t in tasks))
")

echo ""
echo "=========================================="
echo "  ✅ Event initialization complete!"
echo "  ✅ 赛事初始化完成！"
echo "=========================================="
echo "  Modules / 模块  : ${MODULES_ARG}"
echo "  Total points / 总分 : ${TOTAL_POINTS} pts"
echo ""
echo "  Next steps / 下一步："
echo "  1. Start the leaderboard / 启动排行榜（投屏此终端窗口）："
echo ""
echo "     bash automation/refresh-leaderboard.sh \"${EVENT_ID}\""
echo ""
echo "  2. Share with participants / 告知学员："
echo "     EVENT_ID : ${EVENT_ID}"
echo "     JFROG_URL: ${JFROG_URL}"
echo ""
