#!/bin/bash
# Organizer: continuously read all participant progress and render the leaderboard (refreshes every 30s)
# 主办者持续运行：只读取所有学员进展并渲染排行榜（每 30 秒刷新一次）
# Verification logic is on the participant side (check-and-update-progress.sh); this script is read-only
# 验证逻辑已移至学员侧 check-and-update-progress.sh，此脚本不做任何验证或更新

set -eu

usage() {
  cat >&2 <<EOF
Set environment variables first / 使用前请先设置环境变量：
  export JFROG_TOKEN="your-admin-token"
  export JFROG_URL="https://mycompany.jfrog.io"

Usage: $0 <EVENT_ID>

  EVENT_ID    Event ID / 赛事 ID，例如 2026-06-shanghai

Press Ctrl+C to stop. / 按 Ctrl+C 停止。
EOF
  exit 1
}

[ $# -ge 1 ] || usage

EVENT_ID="$1"

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
INTERVAL=30

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

# ── 打印排行榜 ─────────────────────────────────────────────────────────────
print_leaderboard() {
  local all_progress="$1"
  local refresh_time="$2"
  local tasks_json="$3"

  clear
  ALL_PROGRESS_DATA="$all_progress" TASKS_JSON="$tasks_json" python3 - "$EVENT_ID" "$refresh_time" <<'PY'
import sys, json, os

lines = []
for line in os.environ.get('ALL_PROGRESS_DATA', '').splitlines():
    line = line.strip()
    if not line:
        continue
    try:
        data = json.loads(line)
        if 'nickname' in data:
            lines.append(data)
    except:
        pass

tasks_raw = json.loads(os.environ.get('TASKS_JSON', '[]'))
event_id = sys.argv[1]
refresh_time = sys.argv[2]

def last_completed_at(p):
    times = [t.get('completed_at') or '' for t in p.get('tasks', {}).values() if t.get('status') == 'done']
    return max(times) if times else ''

def module_points(p, mod_tasks):
    """Sum points for tasks in a specific module."""
    tasks = p.get('tasks', {})
    return sum(tasks.get(t['id'], {}).get('points', 0) for t in mod_tasks)

def event_points(p):
    tasks = p.get('tasks', {})
    return sum(tasks.get(t['id'], {}).get('points', 0) for t in tasks_raw)

lines.sort(key=lambda x: (-event_points(x), last_completed_at(x)))

def dw(s):
    w = 0
    for c in s:
        cp = ord(c)
        if (cp > 0x2E7F or
                0x1F300 <= cp <= 0x1FAFF or
                0x2300 <= cp <= 0x2BFF):
            w += 2
        else:
            w += 1
    return w

def ljust(s, width):
    return s + ' ' * max(0, width - dw(s))

def rjust(s, width):
    return ' ' * max(0, width - dw(s)) + s

def cjust(s, width):
    pad = max(0, width - dw(s))
    return ' ' * (pad // 2) + s + ' ' * (pad - pad // 2)

def short_label(tid):
    parts = tid.rsplit('-', 1)
    return parts[-1] if len(parts) > 1 else tid

# Build ordered module list preserving task order
modules_seen = []
module_tasks = {}
for t in tasks_raw:
    parts = t['id'].rsplit('-', 1)
    mod = parts[0] if len(parts) > 1 else '_unknown'
    if mod not in modules_seen:
        modules_seen.append(mod)
        module_tasks[mod] = []
    module_tasks[mod].append(t)

max_points = sum(t['points'] for t in tasks_raw)
multi_module = len(modules_seen) > 1

COL_W = 4
NAME_W = 22
RANK_W = 4
ICONS = {"done": "✅", "in_progress": "⏳", "pending": "⬜"}
MEDALS = {1: "🥇", 2: "🥈", 3: "🥉"}

# Outer width — based on widest module block or header lines
def block_width(mod_task_list):
    w = 2 + RANK_W + 1 + NAME_W + 1 + COL_W * len(mod_task_list) + 2 + 6
    return max(w, 60)

header1 = f"  🏆  JFrog Workshop  |  Event ID / 赛事 ID：{event_id}"
header2 = f"  🕐  Updated / 更新时间：{refresh_time}  |  Max / 满分：{max_points} pts"
W = max(
    max((block_width(module_tasks[m]) for m in modules_seen), default=60),
    dw(header1) + 2,
    dw(header2) + 2,
)

print("=" * W)
print(f"  🏆  JFrog Workshop  |  Event ID / 赛事 ID：{event_id}")
print(f"  🕐  Updated / 更新时间：{refresh_time}  |  Max / 满分：{max_points} pts")
print("=" * W)

for mod in modules_seen:
    mod_task_list = module_tasks[mod]
    mod_max = sum(t['points'] for t in mod_task_list)
    bw = block_width(mod_task_list)

    # Rank participants by this module's points for per-module ordering
    mod_sorted = sorted(lines, key=lambda x: (-module_points(x, mod_task_list), last_completed_at(x)))

    title = f"  {mod}  max: {mod_max} pts  "
    prefix = "  ──"
    fill = "─" * max(0, bw - dw(prefix) - dw(title))
    print()
    print(prefix + title + fill)
    header = "  " + ljust("Rank", RANK_W) + " " + ljust("Nickname / 昵称", NAME_W) + " "
    for t in mod_task_list:
        header += cjust(short_label(t['id']), COL_W)
    header += "  " + rjust("Pts", 6)
    print(header)
    print("  " + "-" * (bw - 2))

    for i, p in enumerate(mod_sorted):
        rank = i + 1
        medal = MEDALS.get(rank, f"#{rank:<3}")
        tasks = p.get("tasks", {})
        icons = ""
        for t in mod_task_list:
            status = tasks.get(t['id'], {}).get('status', 'pending')
            icons += cjust(ICONS.get(status, '⬜'), COL_W)
        pts = module_points(p, mod_task_list)
        nickname = p.get("nickname", "")[:NAME_W]
        row = "  " + ljust(medal, RANK_W) + " " + ljust(nickname, NAME_W) + " " + icons + "  " + rjust(f"{pts}pts", 6)
        print(row)

    print("  " + "-" * (bw - 2))

# Overall summary (always shown; especially useful for multi-module)
OW = max(2 + RANK_W + 1 + NAME_W + 2 + 8, 60)
summary_label = "  Overall / 总排行  " if multi_module else "  Summary / 汇总  "
prefix = "  ──"
fill = "─" * max(0, W - dw(prefix) - dw(summary_label))
print()
print(prefix + summary_label + fill)
print("  " + ljust("Rank", RANK_W) + " " + ljust("Nickname / 昵称", NAME_W) + "  " + rjust("Total", 8))
print("  " + "-" * (OW - 2))
for i, p in enumerate(lines):
    rank = i + 1
    medal = MEDALS.get(rank, f"#{rank:<3}")
    pts = event_points(p)
    nickname = p.get("nickname", "")[:NAME_W]
    row = "  " + ljust(medal, RANK_W) + " " + ljust(nickname, NAME_W) + "  " + rjust(f"{pts}pts", 8)
    print(row)
print("  " + "-" * (OW - 2))
print(f"  {len(lines)} participants / 名学员参赛")
print("=" * W)
print()
PY
}

# ── 主循环 ──────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  Leaderboard service started / 排行榜服务启动"
echo "  Event / 赛事：${EVENT_ID}  |  Interval / 刷新间隔：${INTERVAL}s/秒"
echo "  Press Ctrl+C to stop / 按 Ctrl+C 停止"
echo "=========================================="

trap 'echo ""; echo "Leaderboard service stopped. / 排行榜服务已停止。"; exit 0' INT TERM

# ── Fetch task list from event config ─────────────────────────────────────────
echo ">>> Loading event configuration / 加载赛事配置..."
CONFIG_RAW=$(curl_jf \
  "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/config.json" \
  2>/dev/null || echo "")

if [ -z "$CONFIG_RAW" ]; then
  echo "❌ Event config not found for: ${EVENT_ID}" >&2
  echo "❌ 找不到赛事配置：${EVENT_ID}，请先运行 setup-event.sh" >&2
  exit 1
fi

TASKS_JSON=$(echo "$CONFIG_RAW" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(json.dumps(d.get('tasks', []), ensure_ascii=False))
" 2>/dev/null || echo "[]")

EVENT_NAME=$(echo "$CONFIG_RAW" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('event_name', ''))
" 2>/dev/null || echo "")

echo "    ✅ Event: ${EVENT_NAME} | Tasks: $(echo "$TASKS_JSON" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null) tasks"
echo ""

while true; do
  REFRESH_TIME=$(date '+%Y-%m-%d %H:%M:%S')

  PARTICIPANTS=$(curl_jf \
    "${API}/storage/${EVENTS_REPO}/${EVENT_ID}/participants" \
    2>/dev/null \
    | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    names = [c['uri'].strip('/') for c in data.get('children', []) if c.get('folder')]
    print('\n'.join(names))
except:
    pass
" || echo "")

  ALL_PROGRESS=""
  if [ -n "$PARTICIPANTS" ]; then
    while IFS= read -r nickname; do
      [ -n "$nickname" ] || continue
      progress=$(curl_jf \
        "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${nickname}/progress.json" \
        2>/dev/null || echo "")
      [ -n "$progress" ] && ALL_PROGRESS="${ALL_PROGRESS}${progress}
"
    done <<EOF
$PARTICIPANTS
EOF
  fi

  print_leaderboard "$ALL_PROGRESS" "$REFRESH_TIME" "$TASKS_JSON"

  sleep "$INTERVAL"
done
