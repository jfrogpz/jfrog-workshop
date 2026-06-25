#!/bin/bash
# Participant registration: validate nickname, create personal npm repositories,
# upload profile/progress to Artifactory
# 学员注册：验证昵称、创建个人 npm 仓库、上传 profile/progress 到 Artifactory

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROFILE_FILE="${HOME}/.workshop-profile"
EVENTS_REPO="workshop-events"

usage() {
  cat >&2 <<EOF
Set environment variables first / 使用前请先设置环境变量：
  export JFROG_URL="https://mycompany.jfrog.io"
  export JFROG_TOKEN="your-access-token"

Usage: $0 <NICKNAME> [EVENT_ID]

  NICKNAME    Your nickname / 你的昵称（lowercase letters, numbers, hyphens, 3-20 chars / 小写字母、数字、连字符，3-20 个字符）
  EVENT_ID    Event ID provided by instructor / 赛事 ID（由讲师提供）。Omit for self-study mode / 不提供则进入自主学习模式。

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

# ── Step 2: event mode — verify event config and nickname availability ─────────
if [ -n "$EVENT_ID" ]; then
  echo ""
  echo ">>> Fetching event configuration / 获取赛事配置..."
  CONFIG_STATUS=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/config.json" 2>/dev/null || echo "000")

  if [ "$CONFIG_STATUS" != "200" ]; then
    echo "  ❌ Event '${EVENT_ID}' not found. Check EVENT_ID or contact your instructor." >&2
    echo "  ❌ 找不到赛事 ${EVENT_ID}，请确认 EVENT_ID 是否正确，或联系讲师" >&2
    exit 1
  fi
  echo "    ✅ Event configuration confirmed / 赛事配置已确认"

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
NICKNAME=${NICKNAME}
EVENT_ID=${EVENT_ID}
JFROG_URL=${JFROG_URL}
JFROG_TOKEN=${JFROG_TOKEN}
PROF
      echo ""
      echo "  ✅ Registration restored! / 注册信息已恢复！"
      echo "  Run / 运行: bash automation/check-progress.sh"
      echo ""
      exit 0
    else
      echo "  ❌ Nickname '${NICKNAME}' is already taken. Please choose a different one." >&2
      echo "  ❌ 昵称 '${NICKNAME}' 已被其他人使用，请换一个昵称" >&2
      exit 1
    fi
  fi
else
  echo "    ℹ️  Self-study mode, skipping event validation / 自主学习模式，跳过赛事验证"
fi

# ── Step 3: create personal npm repositories ──────────────────────────────────
echo ""
echo ">>> Creating personal npm repositories / 创建个人 npm 仓库（昵称: ${NICKNAME}）..."
echo "    Will create / 将创建：${NICKNAME}-npm-dev-local, ${NICKNAME}-npm-org-remote, ${NICKNAME}-npm-dev-virtual"

if bash "${SCRIPT_DIR}/create-repo.sh" "$NICKNAME"; then
  echo "    ✅ Repositories ready / 仓库就绪"
else
  echo "  ❌ Repository creation failed. Check JFROG_URL and JFROG_TOKEN, then re-run." >&2
  echo "  ❌ 仓库创建失败，请检查 JFROG_URL 和 JFROG_TOKEN 是否正确，然后重新运行注册脚本" >&2
  exit 1
fi

# ── Step 4: initialize progress data ──────────────────────────────────────────
echo ""
echo ">>> Initializing progress data / 初始化进度数据..."
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

# If local self-study progress exists, migrate it to event mode when switching
# 如果本地有自主学习模式的进度文件，切换赛事模式时保留已完成的任务进度
LOCAL_PROGRESS_FILE="${HOME}/.workshop-progress.json"
if [ -n "${EVENT_ID:-}" ] && [ -f "$LOCAL_PROGRESS_FILE" ]; then
  echo "    Local self-study progress detected, migrating to event mode..."
  echo "    检测到本地自主学习进度，将迁移至赛事模式..."
  PROGRESS_JSON=$(EVENT_ID="$EVENT_ID" NICKNAME="$NICKNAME" NOW="$NOW" \
    python3 -c "
import json, os, sys
with open(os.path.expanduser('~/.workshop-progress.json')) as f:
    existing = json.load(f)
existing['nickname'] = os.environ['NICKNAME']
existing['event_id'] = os.environ['EVENT_ID']
t1 = existing.setdefault('tasks', {}).setdefault('T1', {})
if t1.get('status') != 'done':
    t1.update({'status': 'done', 'completed_at': os.environ['NOW'], 'points': 10})
print(json.dumps(existing, ensure_ascii=False))
" 2>/dev/null || echo "")
fi

if [ -z "${PROGRESS_JSON:-}" ]; then
  PROGRESS_JSON=$(cat <<JSON
{
  "nickname": "${NICKNAME}",
  "event_id": "${EVENT_ID:-self-study}",
  "registered_at": "${NOW}",
  "tasks": {
    "T1": { "status": "done",    "completed_at": "${NOW}", "points": 10 },
    "T2": { "status": "pending", "completed_at": null,     "points": 0  },
    "T3": { "status": "pending", "completed_at": null,     "points": 0  },
    "T4": { "status": "pending", "completed_at": null,     "points": 0  },
    "T5": { "status": "pending", "completed_at": null,     "points": 0  },
    "T6": { "status": "pending", "completed_at": null,     "points": 0  }
  },
  "total_points": 10
}
JSON
)
fi

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
    -T -
  echo "$PROGRESS_JSON" | curl_jf -X PUT \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/progress.json" \
    -H "Content-Type: application/json" \
    -T -
  echo "    ✅ Progress uploaded to Artifactory / 进度已上传至 Artifactory"
else
  echo "$PROGRESS_JSON" > "${HOME}/.workshop-progress.json"
  echo "    ✅ Progress saved locally / 进度已保存至本地（~/.workshop-progress.json）"
fi

# ── Step 5: save local profile ────────────────────────────────────────────────
cat > "$PROFILE_FILE" <<PROF
NICKNAME=${NICKNAME}
EVENT_ID=${EVENT_ID:-}
JFROG_URL=${JFROG_URL}
JFROG_TOKEN=${JFROG_TOKEN}
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
echo "  Points / 得分   : 10 (T1 complete / 完成)"
echo ""
echo "  Check your progress / 查看当前进度："
echo "  bash automation/check-progress.sh"
echo ""
echo "  Next task / 下一个任务：T2 - First npm build / 完成首次 npm build"
echo "  Tell the AI assistant you have registered and it will guide you through the next step. ✨"
echo "  请告诉 AI 助理你已完成注册，让它引导你进行下一步 ✨"
echo ""
