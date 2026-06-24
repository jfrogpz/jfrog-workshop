#!/bin/bash
# 主办者持续运行：只读取所有学员进展并渲染排行榜（每 30 秒刷新一次）
# 验证逻辑已移至学员侧 check-progress.sh，此脚本不做任何验证或更新

set -eu

usage() {
  cat >&2 <<EOF
使用前请先设置环境变量：
  export JFROG_TOKEN="your-admin-token"
  export JFROG_URL="https://mycompany.jfrog.io"

Usage: $0 <EVENT_ID>

  EVENT_ID    赛事 ID，例如 2026-06-shanghai

按 Ctrl+C 停止。
EOF
  exit 1
}

[ $# -ge 1 ] || usage

EVENT_ID="$1"

if [ -z "${JFROG_TOKEN:-}" ]; then
  echo "❌ 未设置 JFROG_TOKEN 环境变量，请先运行：" >&2
  echo "   export JFROG_TOKEN=\"your-admin-token\"" >&2
  exit 1
fi

if [ -z "${JFROG_URL:-}" ]; then
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

  clear
  ALL_PROGRESS_DATA="$all_progress" python3 - "$EVENT_ID" "$refresh_time" <<'PY'
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

event_id = sys.argv[1]
refresh_time = sys.argv[2]

def last_completed_at(p):
    times = [t.get('completed_at') or '' for t in p.get('tasks', {}).values() if t.get('status') == 'done']
    return max(times) if times else ''

lines.sort(key=lambda x: (-(x.get('total_points', 0)), last_completed_at(x)))

def dw(s):
    """计算字符串终端显示宽度（CJK/emoji 占 2，ASCII 占 1）"""
    w = 0
    for c in s:
        cp = ord(c)
        if cp > 0x2E7F or (0x1F300 <= cp <= 0x1FAFF):
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

W = 72
print("=" * W)
print(f"  🏆  JFrog Workshop 排行榜   赛事：{event_id}")
print(f"  🕐  更新时间：{refresh_time}")
print("=" * W)
header = "  " + ljust("排名", 4) + " " + ljust("昵称", 22) + " " + \
         cjust("T1", 4) + cjust("T2", 4) + cjust("T3", 4) + \
         cjust("T4", 4) + cjust("T5", 4) + cjust("T6", 4) + \
         "  " + rjust("总分", 6)
print(header)
print("-" * W)

ICONS = {"done": "✅", "in_progress": "⏳", "pending": "⬜"}
MEDALS = {1: "🥇", 2: "🥈", 3: "🥉"}

for i, p in enumerate(lines):
    rank = i + 1
    medal = MEDALS.get(rank, f"  {rank} ")
    tasks = p.get("tasks", {})
    icons = "".join(
        cjust(ICONS.get(tasks.get(tid, {}).get('status', 'pending'), '⬜'), 4)
        for tid in ["T1", "T2", "T3", "T4", "T5", "T6"]
    )
    pts = p.get("total_points", 0)
    nickname = p.get("nickname", "")[:20]
    row = "  " + ljust(medal, 4) + " " + ljust(nickname, 22) + " " + icons + "  " + rjust(f"{pts}分", 6)
    print(row)

print("-" * W)
print(f"  共 {len(lines)} 名学员参赛")
print("=" * W)
print()
PY
}

# ── 主循环 ──────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  排行榜服务启动"
echo "  赛事：${EVENT_ID}  |  刷新间隔：${INTERVAL}秒"
echo "  按 Ctrl+C 停止"
echo "=========================================="

trap 'echo ""; echo "排行榜服务已停止。"; exit 0' INT TERM

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
except Exception as e:
    import sys; print(f'ERROR: {e}', file=sys.stderr)
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

  print_leaderboard "$ALL_PROGRESS" "$REFRESH_TIME"

  sleep "$INTERVAL"
done
