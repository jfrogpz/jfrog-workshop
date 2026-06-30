#!/bin/bash
# xray-npm module: task verification functions
# xray-npm 模块：任务验证函数
#
# Called dynamically by check-and-update-progress.sh via: verify_$(echo "$task_id" | tr '-' '_')
# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller

verify_xray_npm_T1() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-npm-xray-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_xray_npm_T2() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/build/${NICKNAME}-xray-npm-build/1" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_xray_npm_T3() {
  local found="no"
  local offset=0
  local page_size=100
  while true; do
    local page
    page=$(curl_jf "${JFROG_URL}/xray/api/v2/policies?type=security&offset=${offset}&limit=${page_size}" \
      2>/dev/null || echo "")
    local result
    result=$(echo "$page" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    nick = '${NICKNAME}'.lower()
    policies = data if isinstance(data, list) else data.get('policies', [])
    found = any(nick in p.get('name','').lower() for p in policies)
    print('yes' if found else 'no')
    print(len(policies))
except Exception as e:
    print('no')
    print(0)
" 2>/dev/null || printf 'no\n0')
    local page_found page_count
    page_found=$(echo "$result" | sed -n '1p')
    page_count=$(echo "$result" | sed -n '2p')
    if [ "$page_found" = "yes" ]; then found="yes"; break; fi
    [ "${page_count:-0}" -ge "$page_size" ] || break
    offset=$((offset + page_size))
  done
  [ "$found" = "yes" ]
}

verify_xray_npm_T4() {
  local found="no"
  local page
  page=$(curl_jf "${JFROG_URL}/xray/api/v2/watches" 2>/dev/null || echo "")
  found=$(echo "$page" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    nick = '${NICKNAME}'.lower()
    watches = data if isinstance(data, list) else data.get('watches', [])
    f = any(nick in w.get('general_data', {}).get('name', '').lower() for w in watches)
    print('yes' if f else 'no')
except Exception:
    print('no')
" 2>/dev/null || echo "no")
  [ "$found" = "yes" ]
}
