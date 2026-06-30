#!/bin/bash
# Scaffold a new workshop module directory under modules/<module-id>/
# Usage: bash automation/module-author/create-module.sh <module-id>
#
# Creates:
#   modules/<module-id>/tasks.json
#   modules/<module-id>/install-tools.sh
#   modules/<module-id>/create-repo.sh
#   modules/<module-id>/verify-tasks.sh
#   modules/<module-id>/sample-project/.gitkeep

set -euo pipefail

MODULE_ID="${1:-}"
if [ -z "$MODULE_ID" ]; then
  echo "Usage: $0 <module-id>" >&2
  echo "Example: $0 python-basic" >&2
  exit 1
fi

if [[ ! "$MODULE_ID" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "❌ module-id must be lowercase alphanumeric with dashes (e.g. python-basic)" >&2
  exit 1
fi

DIR="modules/${MODULE_ID}"
if [ -d "$DIR" ]; then
  echo "❌ Directory already exists: $DIR" >&2
  exit 1
fi

echo "Creating module: $MODULE_ID"
mkdir -p "$DIR/sample-project"

# ── tasks.json ────────────────────────────────────────────────────────────────
cat > "$DIR/tasks.json" <<JSON
[
  {
    "id": "${MODULE_ID}-T1",
    "name": "TODO: first task name (English)",
    "name_cn": "TODO: 第一个任务（中文）",
    "points": 10,
    "hint": "TODO: hint for task 1",
    "hint_cn": "TODO: 任务 1 提示"
  },
  {
    "id": "${MODULE_ID}-T2",
    "name": "TODO: second task name (English)",
    "name_cn": "TODO: 第二个任务（中文）",
    "points": 20,
    "hint": "TODO: hint for task 2",
    "hint_cn": "TODO: 任务 2 提示"
  }
]
JSON

# ── install-tools.sh ──────────────────────────────────────────────────────────
cat > "$DIR/install-tools.sh" <<'SH'
#!/bin/bash
# MODULE_ID module: verify or install required tools
# Replace MODULE_ID with actual module id in comments above.
#
# ── MANUAL SETUP (without Codespace) ─────────────────────────────────────────
# List tools required by this module and installation instructions here.
# ─────────────────────────────────────────────────────────────────────────────

set -e

# TODO: check/install each required tool
# Example:
# if command -v node >/dev/null 2>&1; then
#   echo "  ✅ node $(node --version)"
# else
#   echo "  Installing Node.js..."
#   curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
#   sudo apt-get install -y nodejs
#   echo "  ✅ node $(node --version)"
# fi

echo "  ✅ install-tools: no additional tools required (update this script)"
SH

# ── create-repo.sh ────────────────────────────────────────────────────────────
cat > "$DIR/create-repo.sh" <<'SH'
#!/bin/bash
# MODULE_ID module: create personal Artifactory repositories for a participant

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

# TODO: replace with actual repo definitions for this module
# Example for npm:
# create_repo "${NICKNAME}-PACKAGETYPE-dev-local" \
#   "{\"rclass\":\"local\",\"packageType\":\"PACKAGETYPE\",\"xrayIndex\":true}"
# create_repo "${NICKNAME}-PACKAGETYPE-org-remote" \
#   "{\"rclass\":\"remote\",\"packageType\":\"PACKAGETYPE\",\"url\":\"UPSTREAM_URL\",\"xrayIndex\":true}"
# create_repo "${NICKNAME}-PACKAGETYPE-dev-virtual" \
#   "{\"rclass\":\"virtual\",\"packageType\":\"PACKAGETYPE\",\"repositories\":[\"${NICKNAME}-PACKAGETYPE-dev-local\",\"${NICKNAME}-PACKAGETYPE-org-remote\"],\"defaultDeploymentRepo\":\"${NICKNAME}-PACKAGETYPE-dev-local\"}"

echo "✅ Repositories ready for ${NICKNAME}"
SH

# ── verify-tasks.sh ───────────────────────────────────────────────────────────
cat > "$DIR/verify-tasks.sh" <<'SH'
#!/bin/bash
# MODULE_ID module: verify task completion for a participant
# Called by: automation/participant/check-and-update-progress.sh
#
# Exit codes:
#   0  — task verified successfully
#   1  — task not yet complete (or verification not implemented)
#
# Usage: bash modules/MODULE_ID/verify-tasks.sh <nickname> <task-id>

set -eu

NICKNAME="${1:-}"
TASK_ID="${2:-}"

if [ -z "$NICKNAME" ] || [ -z "$TASK_ID" ]; then
  echo "Usage: $0 <nickname> <task-id>" >&2
  exit 1
fi

if [ -z "${JFROG_URL:-}" ] || [ -z "${JFROG_TOKEN:-}" ]; then
  echo "❌ JFROG_URL and JFROG_TOKEN environment variables must be set" >&2
  exit 1
fi

JFROG_URL="${JFROG_URL%/}"

# TODO: implement task verification logic
# Example pattern:
# case "$TASK_ID" in
#   MODULE_ID-T1)
#     # Check that the repo exists
#     STATUS=$(curl -sf -o /dev/null -w "%{http_code}" \
#       -H "Authorization: Bearer ${JFROG_TOKEN}" \
#       "${JFROG_URL}/artifactory/api/repositories/${NICKNAME}-myrepo-local" 2>/dev/null || echo "000")
#     [ "$STATUS" = "200" ] && exit 0 || exit 1
#     ;;
#   MODULE_ID-T2)
#     # TODO
#     exit 1
#     ;;
#   *)
#     echo "Unknown task: $TASK_ID" >&2
#     exit 1
#     ;;
# esac

echo "⚠️  verify-tasks.sh not yet implemented for task: $TASK_ID" >&2
exit 1
SH

# ── sample-project placeholder ────────────────────────────────────────────────
touch "$DIR/sample-project/.gitkeep"

# ── make scripts executable ───────────────────────────────────────────────────
chmod +x "$DIR/install-tools.sh" "$DIR/create-repo.sh" "$DIR/verify-tasks.sh"

echo ""
echo "✅ Module scaffolded: $DIR"
echo ""
echo "Next steps:"
echo "  1. Edit $DIR/tasks.json      — define tasks, points, hints"
echo "  2. Edit $DIR/create-repo.sh  — create Artifactory repositories"
echo "  3. Edit $DIR/verify-tasks.sh — implement task verification"
echo "  4. Edit $DIR/install-tools.sh — add tool installation if needed"
echo "  5. Add sample project files under $DIR/sample-project/"
echo "  6. Add an entry in docs/module-catalog.json"
echo "  7. Run: bash automation/module-author/validate-module.sh $MODULE_ID"
