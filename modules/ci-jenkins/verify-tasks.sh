#!/bin/bash
# ci-jenkins module: verify task completion
# Called by: automation/participant/check-and-update-progress.sh

set -eu

NICKNAME="${1:-}"
TASK_ID="${2:-}"

if [ -z "$NICKNAME" ] || [ -z "$TASK_ID" ]; then
  echo "Usage: $0 <nickname> <task-id>" >&2; exit 1
fi
if [ -z "${JFROG_URL:-}" ] || [ -z "${JFROG_TOKEN:-}" ]; then
  echo "❌ JFROG_URL and JFROG_TOKEN must be set" >&2; exit 1
fi

JFROG_URL="${JFROG_URL%/}"
API="${JFROG_URL}/artifactory/api"

curl_jf() {
  curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"
}

http_status() {
  curl_jf -o /dev/null -w "%{http_code}" "$1" 2>/dev/null || echo "000"
}

case "$TASK_ID" in
  ci-jenkins-T1)
    # Verify JFrog plugin connected: check if any build info exists from Jenkins
    # Proxy check: look for a system ping via the configured Artifactory server
    local_count=$(curl_jf "${API}/build" 2>/dev/null \
      | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('builds',[])))" \
      2>/dev/null || echo "0")
    [ "$local_count" -gt 0 ] && exit 0 || exit 1
    ;;

  ci-jenkins-T2)
    # Verify repos created
    s=$(http_status "${API}/repositories/${NICKNAME}-jenkins-npm-virtual")
    [ "$s" = "200" ] && exit 0 || exit 1
    ;;

  ci-jenkins-T3)
    # Verify at least one artifact published to local repo
    children=$(curl_jf "${API}/storage/${NICKNAME}-jenkins-npm-local" 2>/dev/null \
      | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
      2>/dev/null || echo "0")
    [ "$children" -gt 0 ] && exit 0 || exit 1
    ;;

  ci-jenkins-T4)
    # Verify build info published — look for a build named after the participant
    s=$(http_status "${API}/build/${NICKNAME}-jenkins-build")
    [ "$s" = "200" ] && exit 0 || exit 1
    ;;

  ci-jenkins-T5)
    # Verify Xray scan triggered — check for scan status on the build
    result=$(curl_jf "${API}/xray/scanBuild" \
      -X POST -H "Content-Type: application/json" \
      -d "{\"artifactoryId\":\"${NICKNAME}-jenkins-build\",\"version\":\"1\"}" \
      2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('status',''))" \
      2>/dev/null || echo "")
    [ "$result" = "completed" ] && exit 0 || exit 1
    ;;

  *)
    echo "Unknown task: $TASK_ID" >&2; exit 1
    ;;
esac
