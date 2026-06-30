#!/bin/bash
# xray-docker module: task verification functions
# xray-docker 模块：任务验证函数
#
# Called dynamically by check-and-update-progress.sh via: verify_$(echo "$task_id" | tr '-' '_')
# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller

verify_xray_docker_T1() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-docker-xray-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_xray_docker_T2() {
  # Check the local Docker repo has at least one image pushed
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-docker-xray-local" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}

verify_xray_docker_T3() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/build/${NICKNAME}-xray-docker-build/1" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_xray_docker_T4() {
  # Check for both a policy and a watch containing the nickname
  local policy_found="no"
  local page
  page=$(curl_jf "${JFROG_URL}/xray/api/v2/policies?type=security&offset=0&limit=100" \
    2>/dev/null || echo "")
  policy_found=$(echo "$page" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    nick = '${NICKNAME}'.lower()
    policies = data if isinstance(data, list) else data.get('policies', [])
    print('yes' if any(nick in p.get('name','').lower() for p in policies) else 'no')
except Exception:
    print('no')
" 2>/dev/null || echo "no")

  [ "$policy_found" = "yes" ] || return 1

  local watch_found
  local watches
  watches=$(curl_jf "${JFROG_URL}/xray/api/v2/watches" 2>/dev/null || echo "")
  watch_found=$(echo "$watches" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    nick = '${NICKNAME}'.lower()
    items = data if isinstance(data, list) else data.get('watches', [])
    print('yes' if any(nick in w.get('general_data', {}).get('name', '').lower() for w in items) else 'no')
except Exception:
    print('no')
" 2>/dev/null || echo "no")
  [ "$watch_found" = "yes" ]
}
