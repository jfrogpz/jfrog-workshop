#!/bin/bash
# best-practices: create npm repositories following JFrog naming conventions
set -euo pipefail

NICKNAME="${1:-}"
if [[ -z "$NICKNAME" ]]; then
  echo "Usage: $0 <NICKNAME>" >&2
  exit 1
fi

JFROG_URL="${JFROG_URL:-}"
JFROG_TOKEN="${JFROG_TOKEN:-}"
if [[ -z "$JFROG_URL" || -z "$JFROG_TOKEN" ]]; then
  echo "Error: JFROG_URL and JFROG_TOKEN must be set" >&2
  exit 1
fi

create_repo() {
  local repo_key="$1"
  local payload="$2"
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "${JFROG_URL}/artifactory/api/repositories/${repo_key}" \
    -H "Authorization: Bearer ${JFROG_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${payload}")
  if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
    echo "    ✅ Created: ${repo_key}"
  else
    echo "    ⚠️  ${repo_key} (HTTP ${http_code} — may already exist)"
  fi
}

echo "Creating Artifactory repositories for ${NICKNAME} (best-practices)..."

create_repo "${NICKNAME}-npm-bp-local" '{
  "rclass": "local",
  "packageType": "npm",
  "description": "Best practices: local npm repository",
  "xrayIndex": true
}'

create_repo "${NICKNAME}-npm-bp-remote" '{
  "rclass": "remote",
  "packageType": "npm",
  "url": "https://registry.npmjs.org",
  "description": "Best practices: remote npm cache",
  "xrayIndex": true
}'

create_repo "${NICKNAME}-npm-bp-virtual" '{
  "rclass": "virtual",
  "packageType": "npm",
  "description": "Best practices: virtual npm repo",
  "repositories": ["'"${NICKNAME}-npm-bp-local"'", "'"${NICKNAME}-npm-bp-remote"'"],
  "defaultDeploymentRepo": "'"${NICKNAME}-npm-bp-local"'"
}'

echo "✅ Repositories ready for ${NICKNAME}"
