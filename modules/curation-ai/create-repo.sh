#!/bin/bash
# curation-ai module: create personal Artifactory PyPI repositories for a participant
# curation-ai 模块：为学员创建个人 Artifactory PyPI 仓库（AI 包治理）

set -eu

NICKNAME="${1:-}"
if [ -z "$NICKNAME" ]; then
  echo "Usage: $0 <nickname>" >&2
  exit 1
fi

if [ -z "${JFROG_URL:-}" ] || [ -z "${JFROG_TOKEN:-}" ]; then
  echo "❌ JFROG_URL and JFROG_TOKEN environment variables must be set" >&2
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
    echo "    Already exists, skipping: ${key}"
    return 0
  fi
  curl_jf -X PUT "${API}/repositories/${key}" \
    -H "Content-Type: application/json" \
    -d "$body" >/dev/null
  echo "    ✅ Created: ${key}"
}

echo "Creating Artifactory repositories for ${NICKNAME} (curation-ai)..."

create_repo "${NICKNAME}-pypi-ai-local" \
  "{\"rclass\":\"local\",\"packageType\":\"pypi\",\"xrayIndex\":true}"

create_repo "${NICKNAME}-pypi-ai-remote" \
  "{\"rclass\":\"remote\",\"packageType\":\"pypi\",\"url\":\"https://pypi.org\",\"xrayIndex\":true,\"curated\":true}"

create_repo "${NICKNAME}-pypi-ai-virtual" \
  "{\"rclass\":\"virtual\",\"packageType\":\"pypi\",\"repositories\":[\"${NICKNAME}-pypi-ai-local\",\"${NICKNAME}-pypi-ai-remote\"],\"defaultDeploymentRepo\":\"${NICKNAME}-pypi-ai-local\"}"

echo "✅ Repositories ready for ${NICKNAME}"
