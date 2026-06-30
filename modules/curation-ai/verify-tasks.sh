#!/bin/bash
# curation-ai module: task verification functions
# curation-ai 模块：任务验证函数
#
# Called dynamically by check-and-update-progress.sh via: verify_$(echo "$task_id" | tr '-' '_')
# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller

verify_curation_ai_T1() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-pypi-ai-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_curation_ai_T2() {
  # Check the remote cache has content (pip install ran)
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-pypi-ai-remote" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}

verify_curation_ai_T3() {
  local found="no"
  local offset=0
  local page_size=50
  while true; do
    local page
    page=$(curl_jf "${JFROG_URL}/xray/api/v1/curation/policies?num_of_rows=${page_size}&offset=${offset}" \
      2>/dev/null || echo "")
    local result
    result=$(echo "$page" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    nick = '${NICKNAME}'
    policies = data.get('data', [])
    found = any(nick.lower() in p.get('name','').lower() for p in policies)
    total = data.get('meta', {}).get('total_count', 0)
    print('yes' if found else 'no')
    print(total)
except Exception:
    print('no')
    print(0)
" 2>/dev/null || printf 'no\n0')
    local page_found total_count
    page_found=$(echo "$result" | sed -n '1p')
    total_count=$(echo "$result" | sed -n '2p')
    if [ "$page_found" = "yes" ]; then found="yes"; break; fi
    offset=$((offset + page_size))
    [ "$offset" -lt "${total_count:-0}" ] || break
  done
  [ "$found" = "yes" ]
}

verify_curation_ai_T4() {
  # Check Curation audit for a blocked PyPI package pull by this user's repos
  local found="no"
  local offset=0
  local page_size=500
  while true; do
    local page_result
    page_result=$(curl_jf \
      "${JFROG_URL}/xray/api/v1/curation/audit/packages?num_of_rows=${page_size}&offset=${offset}&include_total=true" \
      2>/dev/null || echo "{}")
    local pf pt
    pf=$(echo "$page_result" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    entries = data if isinstance(data, list) else (data.get('packages') or data.get('data') or [])
    meta = {} if isinstance(data, list) else data.get('meta', {})
    nick = '${NICKNAME}'
    f = any(
        nick in str(e.get('curated_repository_name','')) and
        e.get('action','') == 'blocked' and
        'pypi' in str(e.get('package_type','')).lower()
        for e in entries
    )
    print('found=' + ('yes' if f else 'no'))
    print('total=' + str(meta.get('total_count', len(entries))))
    print('count=' + str(len(entries)))
except Exception:
    print('found=no'); print('total=0'); print('count=0')
" 2>/dev/null || printf 'found=no\ntotal=0\ncount=0')
    local page_found total_count page_count
    page_found=$(echo "$pf" | grep '^found=' | cut -d= -f2)
    total_count=$(echo "$pf" | grep '^total=' | cut -d= -f2)
    page_count=$(echo "$pf" | grep '^count=' | cut -d= -f2)
    if [ "$page_found" = "yes" ]; then found="yes"; break; fi
    offset=$((offset + page_size))
    [ "$offset" -lt "${total_count:-0}" ] || break
  done
  [ "$found" = "yes" ]
}
