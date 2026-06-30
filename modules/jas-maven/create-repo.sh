#!/bin/bash
# jas-maven module: create personal Artifactory Maven repositories for a participant
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

echo "Creating Artifactory repositories for ${NICKNAME} (jas-maven)..."

create_repo "${NICKNAME}-maven-jas-local" \
  "{\"rclass\":\"local\",\"packageType\":\"maven\",\"repoLayoutRef\":\"maven-2-default\",\"xrayIndex\":true}"

create_repo "${NICKNAME}-maven-jas-remote" \
  "{\"rclass\":\"remote\",\"packageType\":\"maven\",\"url\":\"https://repo1.maven.org/maven2\",\"repoLayoutRef\":\"maven-2-default\",\"xrayIndex\":true}"

create_repo "${NICKNAME}-maven-jas-virtual" \
  "{\"rclass\":\"virtual\",\"packageType\":\"maven\",\"repoLayoutRef\":\"maven-2-default\",\"repositories\":[\"${NICKNAME}-maven-jas-local\",\"${NICKNAME}-maven-jas-remote\"],\"defaultDeploymentRepo\":\"${NICKNAME}-maven-jas-local\"}"

echo "✅ Repositories ready for ${NICKNAME}"
