#!/bin/bash
# Participant registration: validate nickname, initialize progress, save profile
# 学员注册：验证昵称、初始化进度、保存 profile

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
PROFILE_FILE="${HOME}/.workshop-profile"
EVENTS_REPO="workshop-events"

usage() {
  cat >&2 <<EOF
Set environment variables first / 使用前请先设置环境变量：
  export JFROG_URL="https://mycompany.jfrog.io"
  export JFROG_TOKEN="your-access-token"

Usage: $0 <NICKNAME> [EVENT_ID]

  NICKNAME    Your nickname / 你的昵称（lowercase letters, numbers, hyphens, 3-20 chars）
  EVENT_ID    Event ID provided by instructor / 赛事 ID（由讲师提供）。Omit for self-study / 不提供则进入自主学习模式。

Example (event mode / 参加赛事):
  $0 alex 2026-06-shanghai

Example (self-study / 自主学习):
  $0 alex
EOF
  exit 1
}

[ $# -ge 1 ] || usage

NICKNAME="$1"
EVENT_ID="${2:-}"

# Auto-load saved credentials if not already in environment
# 如果环境变量未设置，自动从本地 profile 加载
if [ -z "${JFROG_URL:-}" ] || [ -z "${JFROG_TOKEN:-}" ]; then
  # shellcheck disable=SC1090
  [ -f "$PROFILE_FILE" ] && . "$PROFILE_FILE" || true
fi

if [ -z "${JFROG_URL:-}" ]; then
  echo "❌ JFROG_URL environment variable is not set. Please run:" >&2
  echo "❌ 未设置 JFROG_URL 环境变量，请先运行：" >&2
  echo "   export JFROG_URL=\"https://mycompany.jfrog.io\"" >&2
  exit 1
fi

if [ -z "${JFROG_TOKEN:-}" ]; then
  echo "❌ JFROG_TOKEN environment variable is not set. Please run:" >&2
  echo "❌ 未设置 JFROG_TOKEN 环境变量，请先运行：" >&2
  echo "   export JFROG_TOKEN=\"your-access-token\"" >&2
  exit 1
fi

JFROG_URL="${JFROG_URL%/}"
GITHUB_USER="${GITHUB_USER:-${GITHUB_ACTOR:-unknown}}"
API="${JFROG_URL}/artifactory/api"

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

echo ""
echo "=========================================="
echo "  JFrog Workshop Participant Registration"
echo "  JFrog Workshop 学员注册"
echo "=========================================="
echo ""

# ── Step 1: validate nickname format ──────────────────────────────────────────
echo ">>> Validating nickname format / 验证昵称格式..."
if ! echo "$NICKNAME" | grep -Eq '^[a-z0-9][a-z0-9-]{1,18}[a-z0-9]$'; then
  echo "" >&2
  echo "  ❌ Invalid nickname: ${NICKNAME}" >&2
  echo "  ❌ 昵称格式不合法：${NICKNAME}" >&2
  echo "  Rules / 规则: lowercase letters, numbers, hyphens; 3-20 chars; must start and end with letter or number" >&2
  echo "  只允许小写字母、数字和连字符，3-20 个字符，首尾必须是字母或数字" >&2
  echo "  Examples / 示例：alex  mary-chen  john2" >&2
  echo "" >&2
  exit 1
fi
echo "    ✅ Nickname valid / 昵称格式正确：${NICKNAME}"

# ── Step 2: fetch config (event mode) or scan local modules (self-study) ──────
TASKS_JSON=""

if [ -n "$EVENT_ID" ]; then
  echo ""
  echo ">>> Fetching event configuration / 获取赛事配置..."
  CONFIG_RAW=$(curl_jf \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/config.json" \
    2>/dev/null || echo "")

  if [ -z "$CONFIG_RAW" ]; then
    echo "  ❌ Event '${EVENT_ID}' not found. Check EVENT_ID or contact your instructor." >&2
    echo "  ❌ 找不到赛事 ${EVENT_ID}，请确认 EVENT_ID 是否正确，或联系讲师" >&2
    exit 1
  fi
  echo "    ✅ Event configuration confirmed / 赛事配置已确认"

  TASKS_JSON=$(echo "$CONFIG_RAW" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(json.dumps(d.get('tasks', []), ensure_ascii=False))
" 2>/dev/null || echo "[]")

  # ── Check nickname availability ──────────────────────────────────────────────
  echo ""
  echo ">>> Checking nickname availability / 检查昵称可用性..."
  PROFILE_STATUS=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/profile.json" \
    2>/dev/null || echo "000")

  if [ "$PROFILE_STATUS" = "200" ]; then
    EXISTING_GITHUB=$(curl_jf \
      "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/profile.json" \
      2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('github_user',''))" \
      2>/dev/null || echo "")

    if [ "$EXISTING_GITHUB" = "$GITHUB_USER" ] || [ "$EXISTING_GITHUB" = "unknown" ]; then
      echo "    ✅ Previous registration detected, restoring local profile..."
      echo "    ✅ 检测到你之前已注册，正在恢复本地配置..."
      cat > "$PROFILE_FILE" <<PROF
export NICKNAME=${NICKNAME}
export EVENT_ID=${EVENT_ID}
export JFROG_URL=${JFROG_URL}
export JFROG_TOKEN=${JFROG_TOKEN}
PROF
      echo ""
      echo "  ✅ Registration restored! / 注册信息已恢复！"
      echo "  Run / 运行: bash automation/participant/check-and-update-progress.sh"
      echo ""
      exit 0
    else
      echo "  ❌ Nickname '${NICKNAME}' is already taken. Please choose a different one." >&2
      echo "  ❌ 昵称 '${NICKNAME}' 已被其他人使用，请换一个昵称" >&2
      exit 1
    fi
  fi
  echo "    ✅ Nickname available / 昵称可用：${NICKNAME}"
else
  echo "    ℹ️  Self-study mode / 自主学习模式"
  TASKS_JSON=$(python3 -c "
import json, os
modules_dir = '${REPO_ROOT}/modules'
tasks = []
for module in sorted(os.listdir(modules_dir)):
    tf = os.path.join(modules_dir, module, 'tasks.json')
    if os.path.isfile(tf):
        mt = json.load(open(tf))
        tasks.extend([{'id': t['id'], 'name': t['name'], 'points': t['points']} for t in mt])
print(json.dumps(tasks, ensure_ascii=False))
" 2>/dev/null || echo "[]")
fi

# ── Step 3: initialize progress — all tasks pending ───────────────────────────
echo ""
echo ">>> Initializing progress / 初始化进度..."
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

PROGRESS_JSON=$(NICKNAME="$NICKNAME" EVENT_ID="${EVENT_ID:-self-study}" NOW="$NOW" \
  TASKS_JSON="$TASKS_JSON" \
  python3 -c "
import json, os
nickname = os.environ['NICKNAME']
event_id = os.environ['EVENT_ID']
now = os.environ['NOW']
tasks_raw = json.loads(os.environ['TASKS_JSON'])
tasks = {t['id']: {'status': 'pending', 'completed_at': None, 'points': 0} for t in tasks_raw}
print(json.dumps({
    'nickname': nickname,
    'event_id': event_id,
    'registered_at': now,
    'tasks': tasks,
    'total_points': 0
}, ensure_ascii=False))
")

# ── Step 4: upload or save progress ───────────────────────────────────────────
if [ -n "$EVENT_ID" ]; then
  PROFILE_JSON=$(cat <<JSON
{
  "nickname": "${NICKNAME}",
  "event_id": "${EVENT_ID}",
  "github_user": "${GITHUB_USER}",
  "registered_at": "${NOW}"
}
JSON
)
  echo "$PROFILE_JSON" | curl_jf -X PUT \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/profile.json" \
    -H "Content-Type: application/json" \
    -T - >/dev/null
  echo "$PROGRESS_JSON" | curl_jf -X PUT \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/progress.json" \
    -H "Content-Type: application/json" \
    -T - >/dev/null
  echo "    ✅ Progress uploaded to Artifactory / 进度已上传至 Artifactory"
else
  echo "$PROGRESS_JSON" > "${HOME}/.workshop-progress.json"
  echo "    ✅ Progress saved locally / 进度已保存至本地（~/.workshop-progress.json）"
fi

# ── Step 5: save local profile ────────────────────────────────────────────────
cat > "$PROFILE_FILE" <<PROF
export NICKNAME=${NICKNAME}
export EVENT_ID=${EVENT_ID:-}
export JFROG_URL=${JFROG_URL}
export JFROG_TOKEN=${JFROG_TOKEN}
PROF

echo ""
echo "=========================================="
echo "  🎉 Registration successful! / 注册成功！"
echo "=========================================="
echo "  Nickname / 昵称 : ${NICKNAME}"
if [ -n "${EVENT_ID:-}" ]; then
  echo "  Event / 赛事    : ${EVENT_ID}"
else
  echo "  Mode / 模式     : Self-study / 自主学习"
fi
echo ""
echo "  Tell the AI assistant you have registered and it will guide you through the next step. ✨"
echo "  请告诉 AI 助理你已完成注册，让它引导你进行下一步 ✨"
echo ""
