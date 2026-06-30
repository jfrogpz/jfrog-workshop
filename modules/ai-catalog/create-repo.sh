#!/bin/bash
# ai-catalog module: create Hugging Face repositories in Artifactory
set -eu

NICKNAME="${1:-}"
if [ -z "$NICKNAME" ]; then
  echo "Usage: $0 <nickname>" >&2
  exit 1
fi

if [ -z "${JFROG_URL:-}" ] || [ -z "${JFROG_TOKEN:-}" ]; then
  echo "❌ JFROG_URL and JFROG_TOKEN environment variables must be set" >&2
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

echo "Creating Artifactory repositories for ${NICKNAME} (ai-catalog)..."

create_repo "${NICKNAME}-hf-local" \
  "{\"rclass\":\"local\",\"packageType\":\"huggingfaceml\",\"xrayIndex\":true}"

create_repo "${NICKNAME}-hf-remote" \
  "{\"rclass\":\"remote\",\"packageType\":\"huggingfaceml\",\"url\":\"https://huggingface.co\",\"xrayIndex\":true,\"curated\":true}"

create_repo "${NICKNAME}-hf-virtual" \
  "{\"rclass\":\"virtual\",\"packageType\":\"huggingfaceml\",\"repositories\":[\"${NICKNAME}-hf-local\",\"${NICKNAME}-hf-remote\"],\"defaultDeploymentRepo\":\"${NICKNAME}-hf-local\"}"

echo "✅ Repositories ready for ${NICKNAME}"
