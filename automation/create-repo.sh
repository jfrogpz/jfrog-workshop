#!/bin/bash
# 为学员创建三个 npm Artifactory 仓库：local、remote、virtual

set -eu

NICKNAME="${1:-}"
if [ -z "$NICKNAME" ]; then
  echo "Usage: $0 <nickname>" >&2
  exit 1
fi

if [ -z "${JFROG_URL:-}" ] || [ -z "${JFROG_TOKEN:-}" ]; then
  echo "❌ 需要设置 JFROG_URL 和 JFROG_TOKEN 环境变量" >&2
  exit 1
fi

JFROG_URL="${JFROG_URL%/}"
API="${JFROG_URL}/artifactory/api"

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

create_repo() {
  local key="$1"
  local body="$2"
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" "${API}/repositories/${key}" 2>/dev/null || echo "000")
  if [ "$s" = "200" ]; then
    echo "    已存在，跳过：${key}"
    return 0
  fi
  curl_jf -X PUT "${API}/repositories/${key}" \
    -H "Content-Type: application/json" \
    -d "$body" >/dev/null
  echo "    ✅ 创建成功：${key}"
}

create_repo "${NICKNAME}-npm-dev-local" \
  "{\"rclass\":\"local\",\"packageType\":\"npm\",\"repoLayoutRef\":\"npm-default\",\"xrayIndex\":true}"

create_repo "${NICKNAME}-npm-remote" \
  "{\"rclass\":\"remote\",\"packageType\":\"npm\",\"url\":\"https://registry.npmjs.org\",\"repoLayoutRef\":\"npm-default\",\"xrayIndex\":true}"

create_repo "${NICKNAME}-npm-virtual" \
  "{\"rclass\":\"virtual\",\"packageType\":\"npm\",\"repoLayoutRef\":\"npm-default\",\"repositories\":[\"${NICKNAME}-npm-dev-local\",\"${NICKNAME}-npm-remote\"],\"defaultDeploymentRepo\":\"${NICKNAME}-npm-dev-local\"}"
