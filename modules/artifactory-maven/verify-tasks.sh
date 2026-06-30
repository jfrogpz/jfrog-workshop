#!/bin/bash
# artifactory-maven module: task verification functions
# artifactory-maven 模块：任务验证函数
#
# Each function is named verify_<TASK_ID> (hyphens replaced with underscores).
# Called dynamically by check-and-update-progress.sh via: verify_$(echo "$task_id" | tr '-' '_')
#
# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller

verify_artifactory_maven_T1() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-maven-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_artifactory_maven_T2() {
  # Verify Maven dependencies were resolved through Artifactory (remote cache has content)
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-maven-remote-cache" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}

verify_artifactory_maven_T3() {
  # Verify Build Info was published
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/build/${NICKNAME}-maven-build" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}
