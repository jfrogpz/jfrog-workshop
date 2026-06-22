#!/bin/bash
# 主办者持续运行：验证所有学员任务进度，更新排行榜（每 30 秒刷新一次）

set -eu

usage() {
  cat >&2 <<EOF
Usage: $0 <EVENT_ID> <JFROG_URL> <JFROG_TOKEN>

  EVENT_ID    赛事 ID，例如 2025-06-shanghai
  JFROG_URL   JFrog 实例地址，例如 https://mycompany.jfrog.io
  JFROG_TOKEN 管理员 Access Token（需要读取所有仓库和 build-info 的权限）

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
      # virtual 仓库存在即视为完成
      local s
      s=$(curl_jf -o /dev/null -w "%{http_code}" \
        "${API}/repositories/${nickname}-npm-virtual" 2>/dev/null || echo "000")
      [ "$s" = "200" ]
      ;;
    T2)
      # dev-local 仓库中有 artifact
      local children
      children=$(curl_jf "${API}/storage/${nickname}-npm-dev-local" 2>/dev/null \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
        2>/dev/null || echo "0")
      [ "$children" -gt 0 ]
      ;;
    T3)
      # Build #1 存在
      local s
      s=$(curl_jf -o /dev/null -w "%{http_code}" \
        "${API}/build/${nickname}-npm-sample/1" 2>/dev/null || echo "000")
      [ "$s" = "200" ]
      ;;
    T4)
      # 存在含昵称的 Curation Policy
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
      # axios@1.7.2 有 curation audit 阻断记录
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
      # Build #3 存在且 axios 版本不是 1.7.2
      local s
      s=$(curl_jf -o /dev/null -w "%{http_code}" \
        "${API}/build/${nickname}-npm-sample/3" 2>/dev/null || echo "000")
      if [ "$s" != "200" ]; then
        return 1
      fi
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
      # 完成条件：有 axios 依赖且不是 1.7.2
      [ -n "$axios_ver" ] && ! echo "$axios_ver" | grep -q "1.7.2"
      ;;
    *)
      return 1
      ;;
  esac
}

# ── 处理单个学员 ────────────────────────────────────────────────────────────
process_participant() {
  local nickname="$1"

  # 拉取当前 progress.json
  local progress_raw
  progress_raw=$(curl_jf \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${nickname}/progress.json" \
    2>/dev/null || echo "")

  [ -n "$progress_raw" ] || return 0

  # 验证每个任务
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

  local updated_progress
  updated_progress=$(echo "$progress_raw" | python3 - "$nickname" "$now" <<'PY'
import sys, json

data = json.loads(sys.stdin.read())
nickname = sys.argv[1]
now = sys.argv[2]

task_points = {"T1": 10, "T2": 20, "T3": 20, "T4": 20, "T5": 20, "T6": 30}
tasks = data.get("tasks", {})

# 只修改 T2-T6（T1 在注册时已标记 done）
for tid in ["T2", "T3", "T4", "T5", "T6"]:
    t = tasks.get(tid, {"status": "pending", "completed_at": None, "points": 0})
    # 从环境变量读取验证结果（由外部 shell 传入）
    import os
    result = os.environ.get(f"VERIFY_{tid}", "fail")
    if result == "pass" and t.get("status") != "done":
        t["status"] = "done"
        t["completed_at"] = now
        t["points"] = task_points[tid]
    elif result == "fail" and t.get("status") == "pending":
        pass  # 保持 pending
    tasks[tid] = t

total = sum(t.get("points", 0) for t in tasks.values())
data["tasks"] = tasks
data["total_points"] = total
print(json.dumps(data, ensure_ascii=False, indent=2))
PY
)

  # 重新验证并设置环境变量
  VERIFY_T2="fail"; VERIFY_T3="fail"; VERIFY_T4="fail"; VERIFY_T5="fail"; VERIFY_T6="fail"
  verify_task "$nickname" T2 2>/dev/null && VERIFY_T2="pass" || true
  verify_task "$nickname" T3 2>/dev/null && VERIFY_T3="pass" || true
  verify_task "$nickname" T4 2>/dev/null && VERIFY_T4="pass" || true
  verify_task "$nickname" T5 2>/dev/null && VERIFY_T5="pass" || true
  verify_task "$nickname" T6 2>/dev/null && VERIFY_T6="pass" || true

  updated_progress=$(VERIFY_T2="$VERIFY_T2" VERIFY_T3="$VERIFY_T3" \
    VERIFY_T4="$VERIFY_T4" VERIFY_T5="$VERIFY_T5" VERIFY_T6="$VERIFY_T6" \
    echo "$progress_raw" | python3 - "$nickname" "$now" <<'PY'
import sys, json, os

data = json.loads(sys.stdin.read())
now = sys.argv[2]

task_points = {"T1": 10, "T2": 20, "T3": 20, "T4": 20, "T5": 20, "T6": 30}
tasks = data.get("tasks", {})

for tid in ["T2", "T3", "T4", "T5", "T6"]:
    t = tasks.get(tid, {"status": "pending", "completed_at": None, "points": 0})
    result = os.environ.get(f"VERIFY_{tid}", "fail")
    if result == "pass" and t.get("status") != "done":
        t["status"] = "done"
        t["completed_at"] = now
        t["points"] = task_points[tid]
    tasks[tid] = t

total = sum(t.get("points", 0) for t in tasks.values())
data["tasks"] = tasks
data["total_points"] = total
print(json.dumps(data, ensure_ascii=False, indent=2))
PY
  )

  # 上传更新后的 progress.json
  echo "$updated_progress" | curl_jf -X PUT \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${nickname}/progress.json" \
    -H "Content-Type: application/json" \
    -T - >/dev/null 2>&1 || true

  echo "$updated_progress"
}

# ── 主循环 ──────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  排行榜刷新服务启动"
echo "  赛事：${EVENT_ID}  |  刷新间隔：${INTERVAL}秒"
echo "  按 Ctrl+C 停止"
echo "=========================================="

trap 'echo ""; echo "排行榜刷新服务已停止。"; exit 0' INT TERM

while true; do
  REFRESH_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
  echo ""
  echo "[$(date '+%H:%M:%S')] 刷新排行榜..."

  # 列出所有学员
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

  if [ -z "$PARTICIPANTS" ]; then
    echo "  （暂无学员注册）"
  else
    # 汇总排行榜数据
    RANKINGS="[]"
    RANKINGS=$(echo "$PARTICIPANTS" | while IFS= read -r nickname; do
      [ -n "$nickname" ] || continue
      progress_json=$(process_participant "$nickname")
      echo "$progress_json"
    done | python3 -c "
import sys, json

all_progress = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        data = json.loads(line)
        if 'nickname' in data:
            all_progress.append(data)
    except json.JSONDecodeError:
        pass  # 跳过非 JSON 行

all_progress.sort(key=lambda x: (-(x.get('total_points', 0)),
                                   x.get('registered_at', '')))

rankings = []
for i, p in enumerate(all_progress):
    tasks = p.get('tasks', {})
    tasks_done = sum(1 for t in tasks.values() if t.get('status') == 'done')
    last_updated = max(
        (t.get('completed_at') or '' for t in tasks.values()),
        default=''
    )
    rankings.append({
        'rank': i + 1,
        'nickname': p.get('nickname'),
        'total_points': p.get('total_points', 0),
        'tasks_done': tasks_done,
        'task_status': {tid: t.get('status', 'pending') for tid, t in tasks.items()},
        'last_updated': last_updated,
    })

print(json.dumps(rankings, ensure_ascii=False))
" 2>/dev/null || echo "[]")

    echo "  学员数量：$(echo "$RANKINGS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo '?')"

    # 上传 leaderboard.json
    LEADERBOARD_JSON=$(cat <<JSON
{
  "event_id": "${EVENT_ID}",
  "updated_at": "${REFRESH_TIME}",
  "rankings": ${RANKINGS}
}
JSON
)
    echo "$LEADERBOARD_JSON" | curl_jf -X PUT \
      "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/leaderboard.json" \
      -H "Content-Type: application/json" \
      -T - >/dev/null 2>&1 && echo "  ✅ 排行榜已更新" || echo "  ⚠️  排行榜更新失败"
  fi

  sleep "$INTERVAL"
done
