#!/bin/bash
# 查看学员当前任务进度（从本地 ~/.workshop-profile 读取配置）

set -eu

PROFILE_FILE="${HOME}/.workshop-profile"
EVENTS_REPO="workshop-events"

# ── 读取本地 profile ────────────────────────────────────────────────────────
if [ ! -f "$PROFILE_FILE" ]; then
  echo "" >&2
  echo "  ❌ 未找到本地配置文件 ~/.workshop-profile" >&2
  echo "  请先运行注册脚本：bash automation/register.sh <昵称> <EVENT_ID> <JFROG_URL> <TOKEN>" >&2
  echo "" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$PROFILE_FILE"

: "${NICKNAME:?}"
: "${EVENT_ID:?}"
: "${JFROG_URL:?}"
: "${JFROG_TOKEN:?}"

JFROG_URL="${JFROG_URL%/}"
API="${JFROG_URL}/artifactory/api"

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

# ── 从 Artifactory 拉取最新 progress.json ─────────────────────────────────
PROGRESS_RAW=$(curl_jf \
  "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/progress.json" \
  2>/dev/null || echo "")

if [ -z "$PROGRESS_RAW" ]; then
  echo "" >&2
  echo "  ❌ 无法获取进度数据，请检查网络或 Token 是否有效" >&2
  exit 1
fi

# ── 解析并输出 ─────────────────────────────────────────────────────────────
echo "$PROGRESS_RAW" | python3 - "$NICKNAME" "$EVENT_ID" <<'PY'
import sys
import json

data = json.loads(sys.stdin.read())
tasks_meta = [
    ("T1", "注册昵称并创建个人仓库",      10),
    ("T2", "完成首次 npm build",          20),
    ("T3", "发布 Build #1 build-info",    20),
    ("T4", "创建 Curation Policy",        10),
    ("T5", "触发 Curation 阻断 axios@1.7.2", 20),
    ("T6", "修复并完成 Build #3",         20),
]

tasks = data.get("tasks", {})
total_points = data.get("total_points", 0)

print("")
print(f"  学员：{data.get('nickname')}  |  赛事：{data.get('event_id')}")
print("  ─────────────────────────────────────────────────")

next_task = None
for tid, tname, tpts in tasks_meta:
    t = tasks.get(tid, {})
    status = t.get("status", "pending")
    pts = t.get("points", 0)
    if status == "done":
        icon = "✅"
        pts_str = f"+{tpts}分"
    elif status == "in_progress":
        icon = "⏳"
        pts_str = "（进行中）"
        if next_task is None:
            next_task = (tid, tname)
    else:
        icon = "⬜"
        pts_str = f"{tpts}分"
        if next_task is None:
            next_task = (tid, tname)
    print(f"  {icon} {tid}  {tname:<28} {pts_str}")

print("  ─────────────────────────────────────────────────")
print(f"  当前总分：{total_points} / 100 分")
print("")

hints = {
    "T2": "进入 npm-sample 目录，配置 npm 指向你的虚拟仓库，然后运行 npm install && npm run build",
    "T3": "执行 jf rt build-publish <build-name> <build-number> 发布 build-info",
    "T4": "在 JFrog UI 中进入 Curation → Policies，创建一条针对 npm 的 Policy",
    "T5": "在你的项目中使用 axios@1.7.2，触发 npm install，观察 Curation 阻断",
    "T6": "将 package.json 中 axios 版本改为安全版本（如 1.6.8），重新构建并发布 Build #3",
}

if next_task:
    tid, tname = next_task
    print(f"  下一步：{tid} - {tname}")
    if tid in hints:
        print(f"  提示   ：{hints[tid]}")
    print("")
else:
    print("  🏆 恭喜！你已完成所有任务！")
    print("")
PY
