#!/bin/bash
# 学员注册：验证昵称、创建个人 npm 仓库、上传 profile/progress 到 Artifactory

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROFILE_FILE="${HOME}/.workshop-profile"
EVENTS_REPO="workshop-events"

usage() {
  cat >&2 <<EOF
使用前请先设置环境变量：
  export JFROG_URL="https://mycompany.jfrog.io"
  export JFROG_TOKEN="your-access-token"

Usage: $0 <NICKNAME> <EVENT_ID>

  NICKNAME    你的昵称（小写字母、数字、连字符，3-20 个字符）
  EVENT_ID    赛事 ID（由讲师提供）

Example:
  export JFROG_URL="https://mycompany.jfrog.io"
  export JFROG_TOKEN="your-access-token"
  $0 alex 2026-06-shanghai
EOF
  exit 1
}

[ $# -ge 2 ] || usage

NICKNAME="$1"
EVENT_ID="$2"

if [ -z "${JFROG_URL:-}" ]; then
  echo "❌ 未设置 JFROG_URL 环境变量，请先运行：" >&2
  echo "   export JFROG_URL=\"https://mycompany.jfrog.io\"" >&2
  exit 1
fi

if [ -z "${JFROG_TOKEN:-}" ]; then
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
echo "  JFrog Workshop 学员注册"
echo "=========================================="
echo ""

# ── 步骤 1：验证昵称格式 ───────────────────────────────────────────────────
echo ">>> 验证昵称格式..."
if ! echo "$NICKNAME" | grep -Eq '^[a-z0-9][a-z0-9-]{1,18}[a-z0-9]$'; then
  echo "" >&2
  echo "  ❌ 昵称格式不合法：${NICKNAME}" >&2
  echo "  规则：只允许小写字母、数字和连字符，3-20 个字符，首尾必须是字母或数字" >&2
  echo "  示例：alex  mary-chen  john2" >&2
  echo "" >&2
  exit 1
fi
echo "    ✅ 昵称格式正确：${NICKNAME}"

# ── 步骤 2：检查赛事配置是否存在 ──────────────────────────────────────────
echo ""
echo ">>> 获取赛事配置..."
CONFIG_STATUS=$(curl_jf -o /dev/null -w "%{http_code}" \
  "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/config.json" 2>/dev/null || echo "000")

if [ "$CONFIG_STATUS" != "200" ]; then
  echo "  ❌ 找不到赛事 ${EVENT_ID}，请确认 EVENT_ID 是否正确，或联系讲师" >&2
  exit 1
fi
echo "    ✅ 赛事配置已确认"

# ── 步骤 3：检查是否已注册（支持 Codespace 重启恢复） ─────────────────────
echo ""
echo ">>> 检查昵称可用性..."
PROFILE_STATUS=$(curl_jf -o /dev/null -w "%{http_code}" \
  "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/profile.json" \
  2>/dev/null || echo "000")

if [ "$PROFILE_STATUS" = "200" ]; then
  # 检查是否是同一个 GitHub 用户（Codespace 重启场景）
  EXISTING_GITHUB=$(curl_jf \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/profile.json" \
    2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('github_user',''))" \
    2>/dev/null || echo "")

  if [ "$EXISTING_GITHUB" = "$GITHUB_USER" ] || [ "$EXISTING_GITHUB" = "unknown" ]; then
    echo "    ✅ 检测到你之前已注册，正在恢复本地配置..."
    cat > "$PROFILE_FILE" <<PROF
NICKNAME=${NICKNAME}
EVENT_ID=${EVENT_ID}
JFROG_URL=${JFROG_URL}
JFROG_TOKEN=${JFROG_TOKEN}
PROF
    echo ""
    echo "  ✅ 注册信息已恢复！"
    echo "  运行 bash automation/check-progress.sh 查看当前进度"
    echo ""
    exit 0
  else
    echo "  ❌ 昵称 '${NICKNAME}' 已被其他人使用，请换一个昵称" >&2
    exit 1
  fi
fi

# ── 步骤 4：创建个人 npm 仓库（通过昵称唯一性验证） ────────────────────────
echo ""
echo ">>> 创建个人 npm 仓库（昵称: ${NICKNAME}）..."
echo "    这将创建三个仓库：${NICKNAME}-npm-dev-local, ${NICKNAME}-npm-remote, ${NICKNAME}-npm-virtual"

# 设置 jf 临时配置（如果还没配置）
if ! jf config show 2>/dev/null | grep -q "Server ID"; then
  jf config add workshop --url="${JFROG_URL}" --access-token="${JFROG_TOKEN}" --interactive=false 2>/dev/null || true
fi

# 调用现有 create-repo.sh
if STUDENT_ID="$NICKNAME" bash "${SCRIPT_DIR}/create-repo.sh" "$NICKNAME" all; then
  echo "    ✅ 仓库创建成功"
else
  echo "  ❌ 仓库创建失败，昵称 '${NICKNAME}' 可能已被占用，请换一个昵称" >&2
  exit 1
fi

# ── 步骤 5：生成并上传 profile.json ───────────────────────────────────────
echo ""
echo ">>> 注册学员信息..."
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

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

# ── 步骤 6：上传初始 progress.json ────────────────────────────────────────
PROGRESS_JSON=$(cat <<JSON
{
  "nickname": "${NICKNAME}",
  "event_id": "${EVENT_ID}",
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

echo "$PROGRESS_JSON" | curl_jf -X PUT \
  "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/progress.json" \
  -H "Content-Type: application/json" \
  -T -

echo "    ✅ 学员信息已上传"

# ── 步骤 7：保存本地 profile ────────────────────────────────────────────────
cat > "$PROFILE_FILE" <<PROF
NICKNAME=${NICKNAME}
EVENT_ID=${EVENT_ID}
JFROG_URL=${JFROG_URL}
JFROG_TOKEN=${JFROG_TOKEN}
PROF

echo ""
echo "=========================================="
echo "  🎉 注册成功！"
echo "=========================================="
echo "  昵称     : ${NICKNAME}"
echo "  赛事     : ${EVENT_ID}"
echo "  获得     : 10 分（T1 完成）"
echo ""
echo "  运行以下命令查看当前进度："
echo "  bash automation/check-progress.sh"
echo ""
echo "  下一个任务：T2 - 完成首次 npm build"
echo "  请告诉 AI 助理你已完成注册，让它引导你进行下一步 ✨"
echo ""
