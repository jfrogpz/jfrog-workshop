#!/bin/bash
# best-practices: task verification functions
# Called by check-and-update-progress.sh — do not execute directly.
# Expects: NICKNAME, JFROG_URL, JFROG_TOKEN, curl_jf() from caller.

verify_best_practices_T1() {
  local http_code
  http_code=$(curl_jf -s -o /dev/null -w "%{http_code}" \
    "${JFROG_URL}/artifactory/api/repositories/${NICKNAME}-npm-bp-virtual")
  [[ "$http_code" == "200" ]]
}

verify_best_practices_T2() {
  # Check group named <nickname>-team exists via Access API
  local http_code
  http_code=$(curl_jf -s -o /dev/null -w "%{http_code}" \
    "${JFROG_URL}/access/api/v2/groups/${NICKNAME}-team")
  [[ "$http_code" == "200" ]]
}

verify_best_practices_T3() {
  # Check permission target named <nickname>-perm exists
  local http_code
  http_code=$(curl_jf -s -o /dev/null -w "%{http_code}" \
    "${JFROG_URL}/artifactory/api/v2/security/permissions/${NICKNAME}-perm")
  [[ "$http_code" == "200" ]]
}

verify_best_practices_T4() {
  # Check JFrog Project exists — project key derived from nickname (lowercase, strip hyphens)
  local project_key
  project_key=$(echo "$NICKNAME" | tr '[:upper:]' '[:lower:]' | tr -d '-')
  local http_code
  http_code=$(curl_jf -s -o /dev/null -w "%{http_code}" \
    "${JFROG_URL}/access/api/v1/projects/${project_key}")
  [[ "$http_code" == "200" ]]
}
