#!/bin/bash
# ci-github-actions module: task verification functions
# ci-github-actions 模块：任务验证函数
#
# Called dynamically by check-and-update-progress.sh via: verify_$(echo "$task_id" | tr '-' '_')
# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller

verify_ci_github_actions_T1() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-npm-gha-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_ci_github_actions_T2() {
  # T2 is configuring GitHub Actions — verify by checking if the remote cache was populated
  # (GitHub Actions would have run npm install through Artifactory)
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-npm-gha-remote" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}

verify_ci_github_actions_T3() {
  # Check that the local repo has artifacts (workflow uploaded something)
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-npm-gha-local" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}

verify_ci_github_actions_T4() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/build/${NICKNAME}-gha-build/1" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_ci_github_actions_T5() {
  # Check that Xray scan was triggered for the build
  local scan_status
  scan_status=$(curl_jf \
    "${JFROG_URL}/xray/api/v1/scanBuild" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"buildName\":\"${NICKNAME}-gha-build\",\"buildNumber\":\"1\"}" \
    2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # If scan exists and has results, status will be non-empty
    status = d.get('status', '') or d.get('more_details', {}).get('status', '')
    print('yes' if status else 'no')
except Exception:
    print('no')
" 2>/dev/null || echo "no")
  [ "$scan_status" = "yes" ]
}
