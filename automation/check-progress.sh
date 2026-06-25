#!/bin/bash
# Participant: verify task progress and upload updates
# 学员运行：自己验证任务进度，并更新进度
# Event mode: EVENT_ID set, progress uploaded to Artifactory
# 赛事模式：EVENT_ID 非空，进度上传至 Artifactory
# Self-study mode: no EVENT_ID, progress stored locally at ~/.workshop-progress.json
# 自主学习模式：EVENT_ID 为空，进度存本地 ~/.workshop-progress.json

set -eu

PROFILE_FILE="${HOME}/.workshop-profile"
EVENTS_REPO="workshop-events"
LOCAL_PROGRESS_FILE="${HOME}/.workshop-progress.json"

# ── 读取本地 profile ────────────────────────────────────────────────────────
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

# ── 判断模式 ────────────────────────────────────────────────────────────────
if [ -n "${EVENT_ID:-}" ]; then
  MODE="event"
else
  MODE="self-study"
fi

# ── 初始化空进度 JSON（T1 标记为 done）────────────────────────────────────────
make_initial_progress() {
  local nick="$1" now="$2" eid="$3"
  python3 -c "
import json, sys
nick, now, eid = sys.argv[1], sys.argv[2], sys.argv[3]
tasks = {}
for tid, pts in [('T1',10),('T2',20),('T3',20),('T4',10),('T5',20),('T6',20)]:
    if tid == 'T1':
        tasks[tid] = {'status': 'done', 'completed_at': now, 'points': pts}
    else:
        tasks[tid] = {'status': 'pending', 'completed_at': None, 'points': 0}
print(json.dumps({'nickname': nick, 'event_id': eid, 'tasks': tasks, 'total_points': 10}, ensure_ascii=False))
" "$nick" "$now" "$eid"
}

# ── 读取当前进度 ─────────────────────────────────────────────────────────────
NOW_INIT=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

if [ "$MODE" = "event" ]; then
  PROGRESS_RAW=$(curl_jf \
    "${JFROG_URL}/artifactory/${EVENTS_REPO}/${EVENT_ID}/participants/${NICKNAME}/progress.json" \
    2>/dev/null || echo "")
  if [ -z "$PROGRESS_RAW" ]; then
    echo "  ⚠️  No progress record in Artifactory, initializing... / Artifactory 中暂无进度记录，初始化本地进度..." >&2
    PROGRESS_RAW=$(make_initial_progress "$NICKNAME" "$NOW_INIT" "$EVENT_ID")
  fi
else
  if [ -f "$LOCAL_PROGRESS_FILE" ]; then
    PROGRESS_RAW=$(cat "$LOCAL_PROGRESS_FILE")
  else
    PROGRESS_RAW=$(make_initial_progress "$NICKNAME" "$NOW_INIT" "self-study")
  fi
fi

# 防御：如果 PROGRESS_RAW 仍为空，直接报错退出
if [ -z "$PROGRESS_RAW" ]; then
  echo "  ❌ Failed to fetch or initialize progress data. Check network or token validity." >&2
  echo "  ❌ 无法获取或初始化进度数据，请检查网络或 Token 是否有效" >&2
  exit 1
fi

# ── 验证单个任务 ────────────────────────────────────────────────────────────
verify_task() {
  local task_id="$1"

  case "$task_id" in
    T1)
      local s
      s=$(curl_jf -o /dev/null -w "%{http_code}" \
        "${API}/repositories/${NICKNAME}-npm-dev-virtual" 2>/dev/null || echo "000")
      [ "$s" = "200" ]
      ;;
    T2)
      local children
      children=$(curl_jf "${API}/storage/${NICKNAME}-npm-org-remote" 2>/dev/null \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
        2>/dev/null || echo "0")
      [ "$children" -gt 0 ]
      ;;
    T3)
      local s
      s=$(curl_jf -o /dev/null -w "%{http_code}" \
        "${API}/build/${NICKNAME}-npm-sample/1" 2>/dev/null || echo "000")
      [ "$s" = "200" ]
      ;;
    T4)
      local found="no"
      local offset=0
      local page_size=50
      while true; do
        local page
        page=$(curl_jf "${JFROG_URL}/xray/api/v1/curation/policies?num_of_rows=${page_size}&offset=${offset}" 2>/dev/null || echo "")
        local result
        result=$(echo "$page" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    nick = '${NICKNAME}'
    policies = data.get('data', [])
    found = any(nick.lower() in p.get('name','').lower() for p in policies)
    total = data.get('meta', {}).get('total_count', 0)
    returned = data.get('meta', {}).get('result_count', 0)
    print('yes' if found else 'no')
    print(total)
    print(returned)
except:
    print('no')
    print(0)
    print(0)
" 2>/dev/null || echo -e "no\n0\n0")
        local page_found total_count result_count
        page_found=$(echo "$result" | sed -n '1p')
        total_count=$(echo "$result" | sed -n '2p')
        result_count=$(echo "$result" | sed -n '3p')
        if [ "$page_found" = "yes" ]; then found="yes"; break; fi
        offset=$((offset + page_size))
        [ "$offset" -lt "${total_count:-0}" ] || break
      done
      [ "$found" = "yes" ]
      ;;
    T5)
      local found="no"
      local offset=0
      local page_size=500
      while true; do
        local page_result
        page_result=$(curl_jf \
          "${JFROG_URL}/xray/api/v1/curation/audit/packages?num_of_rows=${page_size}&offset=${offset}&include_total=true" \
          2>/dev/null || echo "{}")
        local page_found total_count result_count
        page_found=$(echo "$page_result" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    entries = data if isinstance(data, list) else data.get('packages', [])
    nick = '${NICKNAME}'
    f = any(
        nick in str(e.get('curated_repository_name','')) and
        '1.7.2' in str(e.get('package_version','')) and
        'axios' in str(e.get('package_name','')) and
        e.get('action','') == 'blocked'
        for e in entries
    )
    meta = data.get('meta', {}) if isinstance(data, dict) else {}
    print('found=' + ('yes' if f else 'no'))
    print('total=' + str(meta.get('total_count', len(entries))))
    print('count=' + str(len(entries)))
except Exception as ex:
    print('found=no'); print('total=0'); print('count=0')
" 2>/dev/null || printf 'found=no\ntotal=0\ncount=0')
        local pf pt pc
        pf=$(echo "$page_found" | grep '^found=' | cut -d= -f2)
        pt=$(echo "$page_found" | grep '^total=' | cut -d= -f2)
        pc=$(echo "$page_found" | grep '^count=' | cut -d= -f2)
        if [ "$pf" = "yes" ]; then found="yes"; break; fi
        offset=$((offset + page_size))
        [ "$offset" -lt "${pt:-0}" ] || break
      done
      [ "$found" = "yes" ]
      ;;
    T6)
      local s
      s=$(curl_jf -o /dev/null -w "%{http_code}" \
        "${API}/build/${NICKNAME}-npm-sample/3" 2>/dev/null || echo "000")
      if [ "$s" != "200" ]; then return 1; fi
      local axios_ver
      axios_ver=$(curl_jf "${API}/build/${NICKNAME}-npm-sample/3" 2>/dev/null \
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

# ── 对未完成的任务逐一验证，收集结果 ───────────────────────────────────────
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

# 读取各任务当前状态
get_task_status() {
  local tid="$1"
  echo "$PROGRESS_RAW" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tasks', {}).get('$tid', {}).get('status', 'pending'))
" 2>/dev/null || echo "pending"
}

cur_t1=$(get_task_status T1)
cur_t2=$(get_task_status T2)
cur_t3=$(get_task_status T3)
cur_t4=$(get_task_status T4)
cur_t5=$(get_task_status T5)
cur_t6=$(get_task_status T6)

v_t1="fail"; [ "$cur_t1" = "done" ] && v_t1="pass" || { verify_task T1 2>/dev/null && v_t1="pass" || true; }
v_t2="fail"; [ "$cur_t2" = "done" ] && v_t2="pass" || { verify_task T2 2>/dev/null && v_t2="pass" || true; }
v_t3="fail"; [ "$cur_t3" = "done" ] && v_t3="pass" || { verify_task T3 2>/dev/null && v_t3="pass" || true; }
v_t4="fail"; [ "$cur_t4" = "done" ] && v_t4="pass" || { verify_task T4 2>/dev/null && v_t4="pass" || true; }
v_t5="fail"; [ "$cur_t5" = "done" ] && v_t5="pass" || { verify_task T5 2>/dev/null && v_t5="pass" || true; }
v_t6="fail"; [ "$cur_t6" = "done" ] && v_t6="pass" || { verify_task T6 2>/dev/null && v_t6="pass" || true; }

# ── 合并进度，检查是否有新完成的任务 ────────────────────────────────────────
UPDATED=$(VERIFY_T1="$v_t1" VERIFY_T2="$v_t2" VERIFY_T3="$v_t3" \
  VERIFY_T4="$v_t4" VERIFY_T5="$v_t5" VERIFY_T6="$v_t6" \
  PROGRESS_JSON="$PROGRESS_RAW" \
  MODE="$MODE" \
  python3 - "$NOW" "$NICKNAME" <<'PY'
import sys, json, os

data = json.loads(os.environ['PROGRESS_JSON'])
now = sys.argv[1]
nickname = sys.argv[2]
mode = os.environ.get('MODE', 'event')
task_points = {"T1": 10, "T2": 20, "T3": 20, "T4": 10, "T5": 20, "T6": 20}
tasks = data.get("tasks", {})

changed = False
for tid in ["T1", "T2", "T3", "T4", "T5", "T6"]:
    t = tasks.get(tid, {"status": "pending", "completed_at": None, "points": 0})
    if os.environ.get(f"VERIFY_{tid}") == "pass" and t.get("status") != "done":
        t["status"] = "done"
        t["completed_at"] = now
        t["points"] = task_points[tid]
        changed = True
    tasks[tid] = t

data["tasks"] = tasks
data["total_points"] = sum(t.get("points", 0) for t in tasks.values())

# 自主学习模式确保 event_id 字段为 self-study
if mode == "self-study":
    data["event_id"] = "self-study"
if "nickname" not in data:
    data["nickname"] = nickname

# 输出 changed 标志和 JSON
print("changed=" + ("yes" if changed else "no"))
print(json.dumps(data, ensure_ascii=False))
PY
)

CHANGED_FLAG=$(echo "$UPDATED" | head -1 | grep '^changed=' | cut -d= -f2)
UPDATED_JSON=$(echo "$UPDATED" | tail -n +2)

# ── 有新进度时保存 ───────────────────────────────────────────────────────────
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
  # 自主学习模式首次初始化时也写本地文件
  if [ "$MODE" = "self-study" ] && [ ! -f "$LOCAL_PROGRESS_FILE" ]; then
    echo "$UPDATED_JSON" > "$LOCAL_PROGRESS_FILE"
  fi
fi

# ── 打印当前进度 ─────────────────────────────────────────────────────────────
UPDATED_JSON_DATA="$UPDATED_JSON" python3 - "$NICKNAME" "${EVENT_ID:-self-study}" "$MODE" <<'PY'
import sys, json, os

data = json.loads(os.environ['UPDATED_JSON_DATA'])
nickname_arg = sys.argv[1]
event_id_arg = sys.argv[2]
mode = sys.argv[3]

tasks_meta = [
    ("T1", "Register nickname / 注册昵称并创建个人仓库",         10),
    ("T2", "First npm build / 完成首次 npm build",               20),
    ("T3", "Publish Build #1 build-info",                        20),
    ("T4", "Create Curation Policy / 创建 Curation Policy",      10),
    ("T5", "Block axios@1.7.2 / 触发 Curation 阻断 axios@1.7.2", 20),
    ("T6", "Fix and Build #3 / 修复并完成 Build #3",             20),
]

tasks = data.get("tasks", {})
total_points = data.get("total_points", 0)
display_event = data.get("event_id", event_id_arg)

print("")
if mode == "self-study":
    print(f"  Participant / 学员：{data.get('nickname')}  |  Mode / 模式：Self-study / 自主学习")
else:
    print(f"  Participant / 学员：{data.get('nickname')}  |  Event / 赛事：{display_event}")
print("  ─────────────────────────────────────────────────")

next_task = None
for tid, tname, tpts in tasks_meta:
    t = tasks.get(tid, {})
    status = t.get("status", "pending")
    pts = t.get("points", 0)
    if status == "done":
        icon = "✅"
        pts_str = f"+{tpts}pts"
    elif status == "in_progress":
        icon = "⏳"
        pts_str = "(in progress / 进行中)"
        if next_task is None:
            next_task = (tid, tname)
    else:
        icon = "⬜"
        pts_str = f"{tpts}pts"
        if next_task is None:
            next_task = (tid, tname)
    print(f"  {icon} {tid}  {tname:<44} {pts_str}")

print("  ─────────────────────────────────────────────────")
print(f"  Total / 当前总分：{total_points} / 100 pts")
print("")

hints = {
    "T2": "cd npm-sample, configure npm to use your virtual repo, then run: jf npm install --build-name=<NICKNAME>-npm-sample --build-number=1\n       进入 npm-sample 目录，配置 npm 指向你的虚拟仓库，然后运行上面的命令",
    "T3": "Run: jf rt build-publish <build-name> <build-number>\n       执行上面的命令发布 build-info",
    "T4": "In JFrog UI: Curation → Policies → create a new npm Policy\n       在 JFrog UI 中进入 Curation → Policies，创建一条针对 npm 的 Policy",
    "T5": "Use axios@1.7.2 in your project and run jf npm install to trigger Curation blocking\n       在你的项目中使用 axios@1.7.2，触发 npm install，观察 Curation 阻断",
    "T6": "Change axios version in package.json to a safe version (e.g. 1.7.7), rebuild and publish Build #3\n       将 package.json 中 axios 版本改为安全版本（如 1.7.7），重新构建并发布 Build #3",
}

if next_task:
    tid, tname = next_task
    print(f"  Next / 下一步：{tid} - {tname}")
    if tid in hints:
        print(f"  Hint / 提示：{hints[tid]}")
    print("")
else:
    print("  🏆 Congratulations! All tasks complete! / 恭喜！你已完成所有任务！")
    print("")
PY
