#!/bin/bash
# Validate a workshop module directory structure and tasks.json schema
# Usage: bash automation/module-author/validate-module.sh [module-id]
#        Omit module-id to validate ALL modules under modules/

set -euo pipefail

ERRORS=0
WARNINGS=0

err()  { echo "  ❌ $*"; ERRORS=$((ERRORS+1)); }
warn() { echo "  ⚠️  $*"; WARNINGS=$((WARNINGS+1)); }
ok()   { echo "  ✅ $*"; }

validate_module() {
  local id="$1"
  local dir="modules/$id"
  echo ""
  echo "── $id ───────────────────────────────────────────────"

  # ── directory ────────────────────────────────────────────────────────────────
  if [ ! -d "$dir" ]; then
    err "Directory not found: $dir"
    return
  fi
  ok "Directory exists"

  # ── required files ────────────────────────────────────────────────────────────
  for f in tasks.json install-tools.sh create-repo.sh verify-tasks.sh; do
    if [ ! -f "$dir/$f" ]; then
      err "Missing required file: $dir/$f"
    else
      ok "$f present"
    fi
  done

  # ── tasks.json structure ─────────────────────────────────────────────────────
  if [ -f "$dir/tasks.json" ]; then
    if ! python3 -c "import json,sys; json.load(open('$dir/tasks.json'))" 2>/dev/null; then
      err "tasks.json is not valid JSON"
    else
      ok "tasks.json is valid JSON"

      # Check each task has required fields
      python3 - "$dir/tasks.json" "$id" <<'PYEOF'
import json, sys
path, module_id = sys.argv[1], sys.argv[2]
tasks = json.load(open(path))
errors = 0
if not isinstance(tasks, list):
    print("  ❌ tasks.json must be a JSON array")
    sys.exit(1)
for i, t in enumerate(tasks):
    for field in ("id","name","name_cn","points"):
        if field not in t:
            print(f"  ❌ task[{i}] missing field: {field}")
            errors += 1
    if "id" in t and not t["id"].startswith(module_id + "-T"):
        print(f"  ⚠️  task[{i}].id '{t['id']}' should start with '{module_id}-T'")
    if "points" in t and not isinstance(t["points"], int):
        print(f"  ❌ task[{i}].points must be an integer")
        errors += 1
if errors == 0:
    print(f"  ✅ tasks.json schema ok ({len(tasks)} tasks)")
else:
    sys.exit(1)
PYEOF
    fi
  fi

  # ── scripts executable ────────────────────────────────────────────────────────
  for f in install-tools.sh create-repo.sh verify-tasks.sh; do
    if [ -f "$dir/$f" ] && [ ! -x "$dir/$f" ]; then
      warn "$f is not executable (run: chmod +x $dir/$f)"
    fi
  done

  # ── sample-project ────────────────────────────────────────────────────────────
  if [ ! -d "$dir/sample-project" ]; then
    warn "No sample-project/ directory (may be intentional for some modules)"
  else
    ok "sample-project/ directory present"
  fi

  # ── catalog entry ─────────────────────────────────────────────────────────────
  if [ -f "docs/module-catalog.json" ]; then
    if python3 -c "
import json,sys
catalog = json.load(open('docs/module-catalog.json'))
ids = [i['id'] for i in catalog.get('items',[]) if i.get('type')=='module']
sys.exit(0 if '$id' in ids else 1)
" 2>/dev/null; then
      ok "Entry found in docs/module-catalog.json"
    else
      warn "No entry in docs/module-catalog.json — add one when ready"
    fi
  fi
}

# ── main ───────────────────────────────────────────────────────────────────────
if [ "${1:-}" != "" ]; then
  validate_module "$1"
else
  if [ ! -d "modules" ]; then
    echo "❌ No modules/ directory found. Run from repo root." >&2
    exit 1
  fi
  for dir in modules/*/; do
    id="${dir%/}"
    id="${id#modules/}"
    validate_module "$id"
  done
fi

echo ""
echo "──────────────────────────────────────────────────────"
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo "✅ All checks passed"
elif [ "$ERRORS" -eq 0 ]; then
  echo "✅ No errors  ·  ⚠️  $WARNINGS warning(s)"
else
  echo "❌ $ERRORS error(s)  ·  ⚠️  $WARNINGS warning(s)"
  exit 1
fi
