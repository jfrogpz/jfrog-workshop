#!/bin/bash
# ci-jenkins module: create personal Artifactory repositories for a participant

set -eu

NICKNAME="${1:-}"
if [ -z "$NICKNAME" ]; then
  echo "Usage: $0 <nickname>" >&2
  exit 1
fi

if [ -z "${JFROG_URL:-}" ] || [ -z "${JFROG_TOKEN:-}" ]; then
  echo "❌ JFROG_URL and JFROG_TOKEN must be set" >&2
  exit 1
fi

JFROG_URL="${JFROG_URL%/}"
API="${JFROG_URL}/artifactory/api"

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

create_repo() {
  local key="$1" body="$2"
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" "${API}/repositories/${key}" 2>/dev/null || echo "000")
  if [ "$s" = "200" ]; then
    echo "    Already exists: ${key}"; return 0
  fi
  curl_jf -X PUT "${API}/repositories/${key}" \
    -H "Content-Type: application/json" -d "$body" >/dev/null
  echo "    ✅ Created: ${key}"
}

echo "Creating Artifactory repositories for ${NICKNAME} (ci-jenkins)..."

# npm repos — Jenkins pipeline will build an npm project
create_repo "${NICKNAME}-jenkins-npm-local" \
  "{\"rclass\":\"local\",\"packageType\":\"npm\",\"xrayIndex\":true}"

create_repo "${NICKNAME}-jenkins-npm-remote" \
  "{\"rclass\":\"remote\",\"packageType\":\"npm\",\"url\":\"https://registry.npmjs.org\",\"xrayIndex\":true}"

create_repo "${NICKNAME}-jenkins-npm-virtual" \
  "{\"rclass\":\"virtual\",\"packageType\":\"npm\",\"repositories\":[\"${NICKNAME}-jenkins-npm-local\",\"${NICKNAME}-jenkins-npm-remote\"],\"defaultDeploymentRepo\":\"${NICKNAME}-jenkins-npm-local\"}"

echo "✅ Repositories ready for ${NICKNAME}"
