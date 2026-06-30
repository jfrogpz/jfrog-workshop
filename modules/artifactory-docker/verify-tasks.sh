#!/bin/bash
# artifactory-docker module: task verification functions
# artifactory-docker 模块：任务验证函数
#
# Each function is named verify_<TASK_ID> (hyphens replaced with underscores).
# Called dynamically by check-and-update-progress.sh via: verify_$(echo "$task_id" | tr '-' '_')
#
# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller

verify_artifactory_docker_T1() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-docker-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_artifactory_docker_T2() {
  # Verify a Docker image was pulled through the remote proxy (cache should have content)
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-docker-remote-cache" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}

verify_artifactory_docker_T3() {
  # Verify a Docker image was pushed to the local repo
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-docker-local" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}

verify_artifactory_docker_T4() {
  # Verify Build Info was published
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/build/${NICKNAME}-docker-build" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}
