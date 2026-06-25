#!/bin/bash
# npm-security module: task verification functions
# npm-security 模块：任务验证函数
#
# Each function is named verify_<TASK_ID> (hyphens replaced with underscores).
# Called dynamically by check-progress.sh via: verify_$(echo "$task_id" | tr '-' '_')
# 每个函数命名为 verify_<TASK_ID>（连字符替换为下划线）
# 由 check-progress.sh 通过 verify_$(echo "$task_id" | tr '-' '_') 动态调用

# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller
# 依赖调用方设置：NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf()

verify_npm_security_T1() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-npm-dev-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_npm_security_T2() {
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-npm-org-remote" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}

verify_npm_security_T3() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/build/${NICKNAME}-npm-sample/1" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_npm_security_T4() {
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
    local page_found total_count
    page_found=$(echo "$result" | sed -n '1p')
    total_count=$(echo "$result" | sed -n '2p')
    if [ "$page_found" = "yes" ]; then found="yes"; break; fi
    offset=$((offset + page_size))
    [ "$offset" -lt "${total_count:-0}" ] || break
  done
  [ "$found" = "yes" ]
}

verify_npm_security_T5() {
  local found="no"
  local offset=0
  local page_size=500
  while true; do
    local page_result
    page_result=$(curl_jf \
      "${JFROG_URL}/xray/api/v1/curation/audit/packages?num_of_rows=${page_size}&offset=${offset}&include_total=true" \
      2>/dev/null || echo "{}")
    local pf pt pc
    pf=$(echo "$page_result" | python3 -c "
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
    local page_found total_count
    page_found=$(echo "$pf" | grep '^found=' | cut -d= -f2)
    total_count=$(echo "$pf" | grep '^total=' | cut -d= -f2)
    if [ "$page_found" = "yes" ]; then found="yes"; break; fi
    offset=$((offset + page_size))
    [ "$offset" -lt "${total_count:-0}" ] || break
  done
  [ "$found" = "yes" ]
}

verify_npm_security_T6() {
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
}
