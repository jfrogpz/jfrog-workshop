#!/bin/bash
# Participant: verify task progress and upload updates
# 学员运行：验证任务进度并更新
# Event mode: EVENT_ID set, progress uploaded to Artifactory
# Self-study mode: no EVENT_ID, progress stored locally at ~/.workshop-progress.json

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
PROFILE_FILE="${HOME}/.workshop-profile"
EVENTS_REPO="workshop-events"
LOCAL_PROGRESS_FILE="${HOME}/.workshop-progress.json"

# ── Load local profile ─────────────────────────────────────────────────────────
if [ ! -f "$PROFILE_FILE" ]; then
  echo "" >&2
  echo "  ❌ Local profile not found: ~/.workshop-profile" >&2
  echo "  ❌ 未找到本地配置文件 ~/.workshop-profile" >&2
  echo "  Please register first / 请先运行注册脚本：bash automation/register.sh <NICKNAME> [EVENT_ID]" >&2
  echo "" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$PROFILE_FILE"

: "${NICKNAME:?}"
: "${JFROG_URL:?}"
: "${JFROG_TOKEN:?}"

JFROG_URL="${JFROG_URL%/}"
API="${JFROG_URL}/artifactory/api"

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

MODE="self-study"
[ -n "${EVENT_ID:-}" ] && MODE="event"

# ── Load task list from config or local modules ────────────────────────────────
TASKS_JSON=""

if [ "$MODE" = "event" ]; then
  CONFIG_RAW=$(curl_jf \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/config.json" \
    2>/dev/null || echo "")
  if [ -n "$CONFIG_RAW" ]; then
    TASKS_JSON=$(echo "$CONFIG_RAW" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(json.dumps(d.get('tasks', []), ensure_ascii=False))
" 2>/dev/null || echo "[]")
  fi
fi

if [ -z "$TASKS_JSON" ] || [ "$TASKS_JSON" = "[]" ]; then
  TASKS_JSON=$(python3 -c "
import json, os
modules_dir = '${REPO_ROOT}/modules'
tasks = []
for module in sorted(os.listdir(modules_dir)):
    tf = os.path.join(modules_dir, module, 'tasks.json')
    if os.path.isfile(tf):
        mt = json.load(open(tf))
        tasks.extend([{'id': t['id'], 'name': t.get('name',''), 'name_cn': t.get('name_cn',''), 'points': t['points'], 'hint': t.get('hint',''), 'hint_cn': t.get('hint_cn','')} for t in mt])
print(json.dumps(tasks, ensure_ascii=False))
" 2>/dev/null || echo "[]")
fi

# ── Build module→verify_script map ────────────────────────────────────────────
# Source all verify-tasks.sh files found in modules/
for VERIFY_SCRIPT in "${REPO_ROOT}"/modules/*/verify-tasks.sh; do
  if [ -f "$VERIFY_SCRIPT" ]; then
    # shellcheck disable=SC1090
    . "$VERIFY_SCRIPT"
  fi
done

# ── Generic verify dispatcher ─────────────────────────────────────────────────
# Converts task ID to function name: npm-security-T1 → verify_npm_security_T1
dispatch_verify() {
  local task_id="$1"
  local fn_name
  fn_name="verify_$(echo "$task_id" | tr '-' '_')"
  if type "$fn_name" > /dev/null 2>&1; then
    "$fn_name"
  else
    # Unknown task — cannot verify, assume not done
    return 1
  fi
}

# ── Helper: initialize empty progress JSON ────────────────────────────────────
make_initial_progress() {
  local nick="$1" now="$2" eid="$3" tasks_j="$4"
  python3 -c "
import json, sys
nick, now, eid = sys.argv[1], sys.argv[2], sys.argv[3]
tasks_raw = json.loads(sys.argv[4])
tasks = {}
first = True
for t in tasks_raw:
    if first:
        tasks[t['id']] = {'status': 'done', 'completed_at': now, 'points': t['points']}
        first = False
    else:
        tasks[t['id']] = {'status': 'pending', 'completed_at': None, 'points': 0}
total = sum(v.get('points',0) for v in tasks.values())
print(json.dumps({'nickname': nick, 'event_id': eid, 'tasks': tasks, 'total_points': total}, ensure_ascii=False))
" "$nick" "$now" "$eid" "$tasks_j"
}

# ── Read current progress ──────────────────────────────────────────────────────
NOW_INIT=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

if [ "$MODE" = "event" ]; then
  PROGRESS_RAW=$(curl_jf \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/progress.json" \
    2>/dev/null || echo "")
  if [ -z "$PROGRESS_RAW" ]; then
    echo "  ⚠️  No progress record in Artifactory, initializing... / 初始化进度..." >&2
    PROGRESS_RAW=$(make_initial_progress "$NICKNAME" "$NOW_INIT" "$EVENT_ID" "$TASKS_JSON")
  fi
else
  if [ -f "$LOCAL_PROGRESS_FILE" ]; then
    PROGRESS_RAW=$(cat "$LOCAL_PROGRESS_FILE")
  else
    PROGRESS_RAW=$(make_initial_progress "$NICKNAME" "$NOW_INIT" "self-study" "$TASKS_JSON")
  fi
fi

if [ -z "$PROGRESS_RAW" ]; then
  echo "  ❌ Failed to fetch or initialize progress data." >&2
  echo "  ❌ 无法获取或初始化进度数据，请检查网络或 Token 是否有效" >&2
  exit 1
fi

# ── Verify each pending task ───────────────────────────────────────────────────
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

# Get all task IDs from task list
TASK_IDS=$(echo "$TASKS_JSON" | python3 -c "
import sys, json
tasks = json.load(sys.stdin)
for t in tasks:
    print(t['id'])
" 2>/dev/null || echo "")

# For each task: check current status, verify if not yet done, collect results
VERIFY_RESULTS=""
for TASK_ID in $TASK_IDS; do
  CUR_STATUS=$(echo "$PROGRESS_RAW" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tasks', {}).get('${TASK_ID}', {}).get('status', 'pending'))
" 2>/dev/null || echo "pending")

  if [ "$CUR_STATUS" = "done" ]; then
    VERIFY_RESULTS="${VERIFY_RESULTS}${TASK_ID}=pass
"
  else
    if dispatch_verify "$TASK_ID" 2>/dev/null; then
      VERIFY_RESULTS="${VERIFY_RESULTS}${TASK_ID}=pass
"
    else
      VERIFY_RESULTS="${VERIFY_RESULTS}${TASK_ID}=fail
"
    fi
  fi
done

# ── Merge results into progress JSON ──────────────────────────────────────────
UPDATED=$(VERIFY_RESULTS="$VERIFY_RESULTS" PROGRESS_JSON="$PROGRESS_RAW" \
  MODE="$MODE" TASKS_JSON="$TASKS_JSON" \
  python3 - "$NOW" "$NICKNAME" <<'PY'
import sys, json, os

data = json.loads(os.environ['PROGRESS_JSON'])
now = sys.argv[1]
nickname = sys.argv[2]
mode = os.environ.get('MODE', 'event')
tasks_raw = json.loads(os.environ['TASKS_JSON'])
task_points = {t['id']: t['points'] for t in tasks_raw}

verify_lines = os.environ.get('VERIFY_RESULTS', '').strip().splitlines()
verify_map = {}
for line in verify_lines:
    if '=' in line:
        tid, result = line.split('=', 1)
        verify_map[tid.strip()] = result.strip()

tasks = data.get('tasks', {})
changed = False
for tid, result in verify_map.items():
    t = tasks.get(tid, {'status': 'pending', 'completed_at': None, 'points': 0})
    if result == 'pass' and t.get('status') != 'done':
        t['status'] = 'done'
        t['completed_at'] = now
        t['points'] = task_points.get(tid, 0)
        changed = True
    tasks[tid] = t

data['tasks'] = tasks
# In event mode, total_points only counts tasks in this event's task list
# to prevent self-study progress from other modules inflating the score
if mode == 'event':
    data['total_points'] = sum(tasks.get(t['id'], {}).get('points', 0) for t in tasks_raw)
else:
    data['total_points'] = sum(t.get('points', 0) for t in tasks.values())
if mode == 'self-study':
    data['event_id'] = 'self-study'
if 'nickname' not in data:
    data['nickname'] = nickname

print('changed=' + ('yes' if changed else 'no'))
print(json.dumps(data, ensure_ascii=False))
PY
)

CHANGED_FLAG=$(echo "$UPDATED" | head -1 | grep '^changed=' | cut -d= -f2)
UPDATED_JSON=$(echo "$UPDATED" | tail -n +2)

# ── Save if updated ────────────────────────────────────────────────────────────
if [ "$CHANGED_FLAG" = "yes" ]; then
  if [ "$MODE" = "event" ]; then
    echo "$UPDATED_JSON" | curl_jf -X PUT \
      "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/progress.json" \
      -H "Content-Type: application/json" \
      -T - >/dev/null 2>&1 || true
  else
    echo "$UPDATED_JSON" > "$LOCAL_PROGRESS_FILE"
  fi
else
  if [ "$MODE" = "self-study" ] && [ ! -f "$LOCAL_PROGRESS_FILE" ]; then
    echo "$UPDATED_JSON" > "$LOCAL_PROGRESS_FILE"
  fi
fi

# ── Print progress table ───────────────────────────────────────────────────────
UPDATED_JSON_DATA="$UPDATED_JSON" TASKS_JSON="$TASKS_JSON" \
  python3 - "$NICKNAME" "${EVENT_ID:-self-study}" "$MODE" <<'PY'
import sys, json, os

data = json.loads(os.environ['UPDATED_JSON_DATA'])
tasks_raw = json.loads(os.environ['TASKS_JSON'])
nickname_arg = sys.argv[1]
event_id_arg = sys.argv[2]
mode = sys.argv[3]

tasks = data.get('tasks', {})
total_points = data.get('total_points', 0)
max_points = sum(t['points'] for t in tasks_raw)

print('')
if mode == 'self-study':
    print(f"  Participant / 学员：{data.get('nickname')}  |  Mode / 模式：Self-study / 自主学习")
else:
    print(f"  Participant / 学员：{data.get('nickname')}  |  Event / 赛事：{data.get('event_id', event_id_arg)}")
print('  ─────────────────────────────────────────────────')

next_task = None
for t in tasks_raw:
    tid = t['id']
    tname = t.get('name', tid)
    tname_cn = t.get('name_cn', '')
    tpts = t['points']
    task_state = tasks.get(tid, {})
    status = task_state.get('status', 'pending')

    display_name = f"{tname}"
    if tname_cn:
        display_name = f"{tname} / {tname_cn}"

    if status == 'done':
        icon = '✅'
        pts_str = f'+{tpts}pts'
    else:
        icon = '⬜'
        pts_str = f'{tpts}pts'
        if next_task is None:
            next_task = t

    print(f'  {icon} {tid:<22} {display_name:<40} {pts_str}')

print('  ─────────────────────────────────────────────────')
print(f'  Total / 当前总分：{total_points} / {max_points} pts')
print('')

if next_task:
    tid = next_task['id']
    tname = next_task.get('name', tid)
    hint = next_task.get('hint', '')
    hint_cn = next_task.get('hint_cn', '')
    print(f"  Next / 下一步：{tid} - {tname}")
    if hint:
        print(f"  Hint / 提示：{hint}")
    if hint_cn:
        print(f"         {hint_cn}")
    print('')
else:
    print('  🏆 Congratulations! All tasks complete! / 恭喜！你已完成所有任务！')
    print('')
PY
