#!/bin/bash
# ai-catalog module: task verification functions
# Called dynamically by check-and-update-progress.sh via: verify_$(echo "$task_id" | tr '-' '_')
# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller

verify_ai_catalog_T1() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-hf-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_ai_catalog_T3() {
  # Verify a model was downloaded through the remote cache
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-hf-remote" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}

verify_ai_catalog_T5() {
  # Verify a Curation policy containing the nickname was created
  local policies
  policies=$(curl_jf "${JFROG_URL}/xray/api/v1/curation/policies" 2>/dev/null || echo "[]")
  echo "$policies" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    policies = data if isinstance(data, list) else data.get('policies', [])
    nickname = '${NICKNAME}'.lower()
    found = any(nickname in (p.get('name','') or '').lower() for p in policies)
    sys.exit(0 if found else 1)
except:
    sys.exit(1)
"
}
