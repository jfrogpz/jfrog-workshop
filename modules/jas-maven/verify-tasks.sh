#!/bin/bash
# jas-maven module: task verification functions
# Called dynamically by check-and-update-progress.sh via: verify_$(echo "$task_id" | tr '-' '_')
# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller

verify_jas_maven_T1() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-maven-jas-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_jas_maven_T2() {
  # Verify Build Info was published after jf mvn build
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/build/${NICKNAME}-jas-maven-build/1" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_jas_maven_T3() {
  # jf audit --mvn resolves dependencies through Artifactory remote cache
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-maven-jas-remote" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}

verify_jas_maven_T4() {
  # Secrets scan also requires dependencies — same check as T3
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-maven-jas-remote" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}
