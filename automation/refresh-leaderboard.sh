#!/bin/bash
# 主办者持续运行：验证所有学员任务进度，终端实时显示排行榜（每 30 秒刷新一次）

set -eu

usage() {
  cat >&2 <<EOF
Usage: $0 <EVENT_ID> <JFROG_URL> <JFROG_TOKEN>

  EVENT_ID    赛事 ID，例如 2025-06-shanghai
  JFROG_URL   JFrog 实例地址，例如 https://mycompany.jfrog.io
  JFROG_TOKEN 管理员 Access Token

按 Ctrl+C 停止。
EOF
  exit 1
}

[ $# -ge 3 ] || usage

EVENT_ID="$1"
JFROG_URL="${2%/}"
JFROG_TOKEN="$3"

EVENTS_REPO="workshop-events"
API="${JFROG_URL}/artifactory/api"
INTERVAL=30

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

# ── 验证单个任务 ────────────────────────────────────────────────────────────
verify_task() {
  local nickname="$1"
  local task_id="$2"

  case "$task_id" in
    T1)
      local s
      s=$(curl_jf -o /dev/null -w "%{http_code}" \
        "${API}/repositories/${nickname}-npm-virtual" 2>/dev/null || echo "000")
      [ "$s" = "200" ]
      ;;
    T2)
      local children
      children=$(curl_jf "${API}/storage/${nickname}-npm-dev-local" 2>/dev/null \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
        2>/dev/null || echo "0")
      [ "$children" -gt 0 ]
      ;;
    T3)
      local s
      s=$(curl_jf -o /dev/null -w "%{http_code}" \
        "${API}/build/${nickname}-npm-sample/1" 2>/dev/null || echo "000")
      [ "$s" = "200" ]
      ;;
    T4)
      local found
      found=$(curl_jf "${API}/curation/policies" 2>/dev/null \
        | python3 -c "
import sys, json
try:
    policies = json.load(sys.stdin)
    nick = '${nickname}'
    found = any(nick.lower() in (p.get('name','') + p.get('description','')).lower()
                for p in (policies if isinstance(policies, list) else []))
    print('yes' if found else 'no')
except:
    print('no')
" 2>/dev/null || echo "no")
      [ "$found" = "yes" ]
      ;;
    T5)
      local found
      found=$(curl_jf "${API}/curation/audit" 2>/dev/null \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    entries = data if isinstance(data, list) else data.get('results', [])
    nick = '${nickname}'
    found = any(
        nick in str(e.get('repo','')) and
        '1.7.2' in str(e.get('version','')) and
        'axios' in str(e.get('package',''))
        for e in entries
    )
    print('yes' if found else 'no')
except:
    print('no')
" 2>/dev/null || echo "no")
      [ "$found" = "yes" ]
      ;;
    T6)
      local s
      s=$(curl_jf -o /dev/null -w "%{http_code}" \
        "${API}/build/${nickname}-npm-sample/3" 2>/dev/null || echo "000")
      if [ "$s" != "200" ]; then return 1; fi
      local axios_ver
      axios_ver=$(curl_jf "${API}/build/${nickname}-npm-sample/3" 2>/dev/null \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    mods = data.get('buildInfo', {}).get('modules', [])
    for m in mods:
        for dep in m.get('dependencies', []):
            if 'axios' in dep.get('id', '').lower():
                print(dep.get('id',''))
                sys.exit()
    print('')
except:
    print('')
" 2>/dev/null || echo "")
      [ -n "$axios_ver" ] && ! echo "$axios_ver" | grep -q "1.7.2"
      ;;
    *)
      return 1
      ;;
  esac
}

# ── 处理单个学员，返回更新后的 progress JSON ───────────────────────────────
process_participant() {
  local nickname="$1"
  local now="$2"

  local progress_raw
  progress_raw=$(curl_jf \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${nickname}/progress.json" \
    2>/dev/null || echo "")
  [ -n "$progress_raw" ] || return 0

  local v_t2 v_t3 v_t4 v_t5 v_t6
  v_t2="fail"; v_t3="fail"; v_t4="fail"; v_t5="fail"; v_t6="fail"
  verify_task "$nickname" T2 2>/dev/null && v_t2="pass" || true
  verify_task "$nickname" T3 2>/dev/null && v_t3="pass" || true
  verify_task "$nickname" T4 2>/dev/null && v_t4="pass" || true
  verify_task "$nickname" T5 2>/dev/null && v_t5="pass" || true
  verify_task "$nickname" T6 2>/dev/null && v_t6="pass" || true

  local updated
  updated=$(VERIFY_T2="$v_t2" VERIFY_T3="$v_t3" VERIFY_T4="$v_t4" \
    VERIFY_T5="$v_t5" VERIFY_T6="$v_t6" \
    echo "$progress_raw" | python3 - "$now" <<'PY'
import sys, json, os

data = json.loads(sys.stdin.read())
now = sys.argv[1]
task_points = {"T1": 10, "T2": 20, "T3": 20, "T4": 20, "T5": 20, "T6": 30}
tasks = data.get("tasks", {})

for tid in ["T2", "T3", "T4", "T5", "T6"]:
    t = tasks.get(tid, {"status": "pending", "completed_at": None, "points": 0})
    if os.environ.get(f"VERIFY_{tid}") == "pass" and t.get("status") != "done":
        t["status"] = "done"
        t["completed_at"] = now
        t["points"] = task_points[tid]
    tasks[tid] = t

data["tasks"] = tasks
data["total_points"] = sum(t.get("points", 0) for t in tasks.values())
print(json.dumps(data, ensure_ascii=False))
PY
  )

  echo "$updated" | curl_jf -X PUT \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${nickname}/progress.json" \
    -H "Content-Type: application/json" \
    -T - >/dev/null 2>&1 || true

  echo "$updated"
}

# ── 打印排行榜 ─────────────────────────────────────────────────────────────
print_leaderboard() {
  local all_progress="$1"
  local refresh_time="$2"

  clear
  echo "$all_progress" | python3 - "$EVENT_ID" "$refresh_time" <<'PY'
import sys, json

lines = []
for line in sys.stdin:
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

lines.sort(key=lambda x: (-(x.get('total_points', 0)), x.get('registered_at', '')))

TASK_NAMES = {
    "T1": "注册",
    "T2": "构建",
    "T3": "发布",
    "T4": "策略",
    "T5": "阻断",
    "T6": "修复",
}

W = 72
print("=" * W)
print(f"  🏆  JFrog Workshop 排行榜   赛事：{event_id}")
print(f"  🕐  更新时间：{refresh_time}")
print("=" * W)
print(f"  {'排名':<4} {'昵称':<22} {'T1':^4}{'T2':^4}{'T3':^4}{'T4':^4}{'T5':^4}{'T6':^4}  {'总分':>6}")
print("-" * W)

ICONS = {"done": "✅", "in_progress": "⏳", "pending": "⬜"}
MEDALS = {1: "🥇", 2: "🥈", 3: "🥉"}

for i, p in enumerate(lines):
    rank = i + 1
    medal = MEDALS.get(rank, f"  {rank} ")
    tasks = p.get("tasks", {})
    icons = "".join(
        f"{ICONS.get(tasks.get(tid, {}).get('status', 'pending'), '⬜'):^4}"
        for tid in ["T1", "T2", "T3", "T4", "T5", "T6"]
    )
    pts = p.get("total_points", 0)
    nickname = p.get("nickname", "")[:20]
    print(f"  {medal:<4} {nickname:<22} {icons}  {pts:>5}分")

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
  NOW=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
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
" 2>/dev/null || echo "")

  ALL_PROGRESS=""
  if [ -n "$PARTICIPANTS" ]; then
    while IFS= read -r nickname; do
      [ -n "$nickname" ] || continue
      progress=$(process_participant "$nickname" "$NOW")
      [ -n "$progress" ] && ALL_PROGRESS="${ALL_PROGRESS}${progress}
"
    done <<EOF
$PARTICIPANTS
EOF
  fi

  print_leaderboard "$ALL_PROGRESS" "$REFRESH_TIME"

  sleep "$INTERVAL"
done
