#!/bin/bash
# Analyze module/resource content with Claude AI and update tags in docs/module-catalog.json
# Also supports --discover mode: AI searches for new JFrog learning resources to add to catalog.
#
# Usage:
#   bash automation/module-author/update-catalog-tags.sh              # analyze all items
#   bash automation/module-author/update-catalog-tags.sh npm-basic    # analyze one item
#   bash automation/module-author/update-catalog-tags.sh --dry-run    # show changes without writing
#   bash automation/module-author/update-catalog-tags.sh --yes        # apply all without prompting
#   bash automation/module-author/update-catalog-tags.sh --discover   # find new resources from the web
#
# Requirements (one of):
#   claude CLI (Claude Code) — installed and logged in, OR
#   ANTHROPIC_API_KEY env var — from console.anthropic.com
#   python3 — always required

set -euo pipefail

CATALOG="docs/module-catalog.json"
DRY_RUN=false
AUTO_YES=false
DISCOVER=false
TARGET=""
MODEL="${ANTHROPIC_MODEL:-claude-haiku-4-5-20251001}"  # used when calling API directly
CHANGED=0

# ── parse args ────────────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --yes)      AUTO_YES=true ;;
    --discover) DISCOVER=true ;;
    --*)        echo "Unknown flag: $arg" >&2; exit 1 ;;
    *)          TARGET="$arg" ;;
  esac
done

# ── check requirements ────────────────────────────────────────────────────────
if ! command -v python3 >/dev/null 2>&1; then
  echo "❌  Required tool not found: python3" >&2; exit 1
fi
if command -v claude >/dev/null 2>&1; then
  BACKEND="claude-cli"
elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  BACKEND="api"
else
  echo "❌  No AI backend available. Need one of:" >&2
  echo "    1. Claude Code CLI (claude) — install: https://claude.ai/code" >&2
  echo "    2. export ANTHROPIC_API_KEY=sk-ant-... (from console.anthropic.com)" >&2
  exit 1
fi
if [ ! -f "$CATALOG" ]; then
  echo "❌  $CATALOG not found. Run from repo root." >&2; exit 1
fi

# ── helpers ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'; BOLD='\033[1m'

call_claude() {
  local prompt="$1"
  if [ "$BACKEND" = "claude-cli" ]; then
    claude -p "$prompt" 2>/dev/null
  else
    local payload
    payload=$(python3 -c "
import json, sys
prompt = sys.stdin.read()
print(json.dumps({
  'model': '${MODEL}',
  'max_tokens': 512,
  'messages': [{'role': 'user', 'content': prompt}]
}))
" <<< "$prompt")
    local resp
    resp=$(curl -sf https://api.anthropic.com/v1/messages \
      -H "x-api-key: ${ANTHROPIC_API_KEY}" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d "$payload") || return 1
    echo "$resp" | python3 -c "
import json,sys
d=json.load(sys.stdin)
if 'error' in d: print(d['error']['message'],file=sys.stderr); exit(1)
print(d['content'][0]['text'])
"
  fi
}

extract_tags() {
  # claude -p returns plain text — find the JSON object in it
  python3 -c "
import json, sys, re
text = sys.stdin.read().strip()
m = re.search(r'\{[^{}]+\}', text, re.DOTALL)
if not m:
    print('PARSE_ERROR: ' + text[:200], file=sys.stderr)
    sys.exit(1)
tags = json.loads(m.group())
for k in ('scenario','role','ecosystem'):
    if k not in tags or not isinstance(tags[k], list):
        print(f'SCHEMA_ERROR: missing key: {k}', file=sys.stderr)
        sys.exit(1)
print(json.dumps(tags))
"
}

build_module_prompt() {
  local id="$1"
  local desc_en="$2"
  local desc_zh="$3"
  local tasks_text="$4"
  local instr_text="$5"

  cat <<PROMPT
You are cataloging a JFrog Workshop module. Analyze the content and assign tags.

MODULE ID: ${id}
DESCRIPTION (EN): ${desc_en}
DESCRIPTION (ZH): ${desc_zh}

TASKS:
${tasks_text:-"(none defined yet)"}

${instr_text:+INSTRUCTIONS EXCERPT:
${instr_text}}

───────────────────────────────────────
Assign tags from ONLY these allowed values:

scenario (pick all that apply):
  workshop        — hands-on lab, participants do tasks step by step
  poc             — useful for demonstrating value in a proof-of-concept
  onboarding      — good starting point for new users learning the basics

role (pick all that apply):
  developer   — code build/publish tasks a developer would do
  security    — security scanning, policy, compliance tasks
  devsecops   — cross-functional pipeline + security integration tasks
  admin       — platform configuration, permissions, repo management

ecosystem (pick all that apply — use [] if not tied to a specific package ecosystem):
  npm, maven, docker, python, helm

───────────────────────────────────────
Respond with ONLY a JSON object, no explanation, no markdown:
{"scenario": [...], "role": [...], "ecosystem": [...]}
PROMPT
}

build_resource_prompt() {
  local id="$1"
  local title_en="$2"
  local title_zh="$3"
  local desc_en="$4"
  local desc_zh="$5"
  local source="$6"
  local content_lang="$7"

  cat <<PROMPT
You are cataloging a JFrog learning resource. Analyze and assign tags.

RESOURCE ID: ${id}
SOURCE: ${source}
LANGUAGE: ${content_lang}
TITLE (EN): ${title_en}
TITLE (ZH): ${title_zh}
DESCRIPTION (EN): ${desc_en}
DESCRIPTION (ZH): ${desc_zh}

───────────────────────────────────────
Assign tags from ONLY these allowed values:

scenario: workshop, poc, onboarding
role:     developer, security, devsecops, admin
ecosystem: npm, maven, docker, python, helm  (use [] if not ecosystem-specific)

Respond with ONLY a JSON object, no explanation, no markdown:
{"scenario": [...], "role": [...], "ecosystem": [...]}
PROMPT
}

tags_equal() {
  python3 -c "
import json, sys
a = json.loads(sys.argv[1])
b = json.loads(sys.argv[2])
for k in ('scenario','role','ecosystem'):
    if sorted(a.get(k,[])) != sorted(b.get(k,[])):
        sys.exit(1)
" "$1" "$2" 2>/dev/null
}

format_tag_diff() {
  local key="$1" old_json="$2" new_json="$3"
  python3 -c "
import json, sys
old = sorted(json.loads(sys.argv[1]).get(sys.argv[2],[]))
new = sorted(json.loads(sys.argv[3]).get(sys.argv[2],[]))
old_str = '[' + ', '.join(old) + ']'
new_str = '[' + ', '.join(new) + ']'
if old == new:
    print(f'  {sys.argv[2]:12s} {old_str}')
else:
    print(f'  {sys.argv[2]:12s} {old_str}  →  {new_str}  ★')
" "$old_json" "$key" "$new_json"
}

apply_tags() {
  # update tags for item id in catalog JSON
  local id="$1" new_tags="$2"
  python3 - "$CATALOG" "$id" "$new_tags" <<'PYEOF'
import json, sys
catalog_path, item_id, new_tags_str = sys.argv[1], sys.argv[2], sys.argv[3]
new_tags = json.loads(new_tags_str)
with open(catalog_path) as f:
    catalog = json.load(f)
for item in catalog['items']:
    if item['id'] == item_id:
        item['tags'] = new_tags
        break
with open(catalog_path, 'w') as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write('\n')
PYEOF
}

# ── process one catalog item ──────────────────────────────────────────────────
process_item() {
  local item_json="$1"
  local id type source
  id=$(echo "$item_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
  type=$(echo "$item_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['type'])")
  source=$(echo "$item_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['source'])")

  echo ""
  printf "${BOLD}── %s${RESET} (%s)\n" "$id" "$type"

  local old_tags prompt new_tags_json

  old_tags=$(echo "$item_json" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['tags']))")

  # ── build prompt per type ──────────────────────────────────────────────────
  if [ "$type" = "module" ]; then
    local desc_en desc_zh tasks_text instr_text
    desc_en=$(echo "$item_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('desc_en',''))")
    desc_zh=$(echo "$item_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('desc_zh',''))")

    # read tasks
    tasks_text=""
    if [ -f "modules/$id/tasks.json" ]; then
      tasks_text=$(python3 -c "
import json
tasks = json.load(open('modules/$id/tasks.json'))
for i,t in enumerate(tasks,1):
    print(f'{i}. {t.get(\"name\",\"\")}  /  {t.get(\"name_cn\",\"\")}')" 2>/dev/null || true)
    fi

    # read instructions (first 1800 chars)
    instr_text=""
    for f in \
      ".github/instructions/${id}.instructions.md" \
      ".github/instructions/${id}.instructions-en.md"; do
      if [ -f "$f" ]; then
        instr_text=$(head -c 1800 "$f" 2>/dev/null || true)
        break
      fi
    done

    prompt=$(build_module_prompt "$id" "$desc_en" "$desc_zh" "$tasks_text" "$instr_text")
  else
    local title_en title_zh d_en d_zh content_lang
    title_en=$(echo "$item_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('title_en',''))")
    title_zh=$(echo "$item_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('title_zh',''))")
    d_en=$(echo "$item_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('desc_en',''))")
    d_zh=$(echo "$item_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('desc_zh',''))")
    content_lang=$(echo "$item_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('content_lang','en'))")
    prompt=$(build_resource_prompt "$id" "$title_en" "$title_zh" "$d_en" "$d_zh" "$source" "$content_lang")
  fi

  # ── call API ───────────────────────────────────────────────────────────────
  printf "  Analyzing with Claude... "
  local api_response
  api_response=$(call_claude "$prompt" 2>&1) || { echo "curl error"; return 1; }

  new_tags_json=$(echo "$api_response" | extract_tags 2>&1) || {
    echo ""
    echo "  ⚠️  Could not parse AI response, skipping."
    echo "     Response: $(echo "$api_response" | head -c 200)"
    return
  }
  echo "done"

  # ── show diff ──────────────────────────────────────────────────────────────
  if tags_equal "$old_tags" "$new_tags_json"; then
    echo "  ✅ Tags unchanged"
    return
  fi

  echo "  Changes proposed:"
  for key in scenario role ecosystem; do
    format_tag_diff "$key" "$old_tags" "$new_tags_json"
  done

  # ── write or skip ──────────────────────────────────────────────────────────
  if $DRY_RUN; then
    echo "  (dry-run — not written)"
    return
  fi

  local apply=false
  if $AUTO_YES; then
    apply=true
  else
    printf "  Apply? [y/N] "
    read -r answer < /dev/tty
    [[ "$answer" =~ ^[Yy]$ ]] && apply=true
  fi

  if $apply; then
    apply_tags "$id" "$new_tags_json"
    printf "  ${GREEN}✅ Updated${RESET}\n"
    CHANGED=$((CHANGED+1))
  else
    echo "  Skipped"
  fi
}

# ── discover: find new resources from the internet ───────────────────────────
run_discover() {
  echo ""
  printf "${CYAN}${BOLD}discover mode${RESET}\n"
  echo "Asking Claude to recommend JFrog learning resources..."
  echo ""

  # get existing resource IDs + URLs so AI can avoid duplicates
  local existing
  existing=$(python3 -c "
import json
catalog = json.load(open('$CATALOG'))
for item in catalog['items']:
    if item['type'] == 'resource':
        print(f\"{item['id']}  {item.get('url','')}  — {item.get('title_en','')}\")" )

  local schema='{
  "type": "object",
  "properties": {
    "resources": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id":           {"type": "string"},
          "source":       {"type": "string", "enum": ["youtube","jfrog-docs","jfrog-china","github","other"]},
          "title_en":     {"type": "string"},
          "title_zh":     {"type": "string"},
          "desc_en":      {"type": "string"},
          "desc_zh":      {"type": "string"},
          "url":          {"type": "string"},
          "content_lang": {"type": "string", "enum": ["en","zh","both"]},
          "tags": {
            "type": "object",
            "properties": {
              "scenario":  {"type": "array", "items": {"type": "string"}},
              "role":      {"type": "array", "items": {"type": "string"}},
              "ecosystem": {"type": "array", "items": {"type": "string"}}
            }
          }
        },
        "required": ["id","source","title_en","title_zh","desc_en","desc_zh","url","content_lang","tags"]
      }
    }
  }
}'

  local prompt
  prompt=$(cat <<PROMPT
You are curating a JFrog Workshop resource catalog for a hands-on security workshop.
The workshop audience is developers and security engineers in China learning JFrog supply chain security.

EXISTING RESOURCES (do NOT suggest these again):
${existing}

YOUR TASK:
Suggest 5-8 high-quality JFrog learning resources that would complement this workshop.
Focus on:
- Specific YouTube videos from the JFrog channel (youtube.com/watch?v=...) about Xray, Curation, Artifactory, supply chain security
- JFrogChina webinars (jfrogchina.com/webinar/...) — in Chinese, useful for Chinese-speaking audience
- JFrog Academy courses (academy.jfrog.com) — free self-paced learning paths
- Official JFrog documentation pages relevant to hands-on tasks (jfrog.com/help/...)
- GitHub repos from github.com/jfrogtraining with real workshop content

IMPORTANT: Only suggest resources with REAL, SPECIFIC URLs you are confident exist.
Do NOT suggest homepage URLs (like youtube.com/@JFrog or github.com/jfrog).
Each YouTube URL must be a specific video: youtube.com/watch?v=VIDEOID

For each resource, generate:
- id: kebab-case slug (e.g. yt-xray-demo-2024, jf-academy-xray, jfcn-buildinfo-webinar)
- source: one of youtube / jfrog-docs / jfrog-china / github / other
- title_en / title_zh: clear titles
- desc_en / desc_zh: 1-sentence description
- url: the specific URL
- content_lang: en / zh / both
- tags: scenario/role/ecosystem from allowed values:
    scenario: workshop, poc, onboarding
    role: developer, security, devsecops, admin
    ecosystem: npm, maven, docker, python, helm  ([] if not ecosystem-specific)

Respond with ONLY a JSON object:
{"resources": [...]}
PROMPT
)

  printf "  Calling Claude (this may take ~15s)... "
  local raw_response
  raw_response=$(call_claude "$prompt") || { echo "error"; return 1; }

  # parse response — find the {"resources":[...]} object
  local suggestions
  suggestions=$(echo "$raw_response" | python3 -c "
import json, sys, re
text = sys.stdin.read().strip()
m = re.search(r'\{.*\}', text, re.DOTALL)
if not m:
    print('PARSE_ERROR', file=sys.stderr)
    sys.exit(1)
obj = json.loads(m.group())
print(json.dumps(obj.get('resources', []), ensure_ascii=False, indent=2))
" 2>&1) || {
    echo ""
    echo "  ⚠️  Could not parse AI response."
    echo "     $suggestions"
    return
  }
  echo "done"

  local count
  count=$(echo "$suggestions" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")
  echo ""
  echo "  Claude suggested $count resources:"
  echo ""

  # display each suggestion and ask whether to add
  local added=0
  while IFS= read -r res_json; do
    local rid rtitle_en rdesc_en rurl rsource
    rid=$(echo "$res_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
    rtitle_en=$(echo "$res_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['title_en'])")
    rdesc_en=$(echo "$res_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['desc_en'])")
    rurl=$(echo "$res_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['url'])")
    rsource=$(echo "$res_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['source'])")

    printf "${BOLD}  [%s]${RESET} %s\n" "$rid" "$rtitle_en"
    echo "       $rdesc_en"
    printf "       ${CYAN}%s${RESET}\n" "$rurl"

    # check if id already exists
    local already_exists
    already_exists=$(python3 -c "
import json
catalog = json.load(open('$CATALOG'))
ids = [i['id'] for i in catalog['items']]
print('yes' if '$rid' in ids else 'no')
")
    if [ "$already_exists" = "yes" ]; then
      echo "       (already in catalog — skipped)"
      echo ""
      continue
    fi

    if $DRY_RUN; then
      echo "       (dry-run — not added)"
      echo ""
      continue
    fi

    local do_add=false
    if $AUTO_YES; then
      do_add=true
    else
      printf "       Add to catalog? [y/N] "
      read -r answer < /dev/tty
      [[ "$answer" =~ ^[Yy]$ ]] && do_add=true
    fi

    if $do_add; then
      # append to catalog items array
      python3 - "$CATALOG" "$res_json" <<'PYEOF'
import json, sys
catalog_path = sys.argv[1]
new_item_str = sys.argv[2]
new_item = json.loads(new_item_str)
# build full resource item
item = {
  "id":           new_item["id"],
  "type":         "resource",
  "status":       "available",
  "source":       new_item["source"],
  "title_en":     new_item["title_en"],
  "title_zh":     new_item["title_zh"],
  "desc_en":      new_item["desc_en"],
  "desc_zh":      new_item["desc_zh"],
  "duration_min": 0,
  "content_lang": new_item["content_lang"],
  "url":          new_item["url"],
  "tags":         new_item["tags"],
  "tasks":        []
}
with open(catalog_path) as f:
    catalog = json.load(f)
catalog["items"].append(item)
with open(catalog_path, "w") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"  ✅ Added: {item['id']}")
PYEOF
      added=$((added+1))
    else
      echo "       Skipped"
    fi
    echo ""
  done < <(echo "$suggestions" | python3 -c "
import json, sys
items = json.load(sys.stdin)
for item in items:
    print(json.dumps(item, ensure_ascii=False))
")

  echo "──────────────────────────────────────────────────"
  if $DRY_RUN; then
    echo "Dry-run complete. No files were modified."
  elif [ "$added" -gt 0 ]; then
    printf "${GREEN}✅ Added $added new resource(s) to $CATALOG${RESET}\n"
    echo "   Review changes with: git diff $CATALOG"
  else
    echo "No resources added."
  fi
}

# ── main ───────────────────────────────────────────────────────────────────────
if $DISCOVER; then
  run_discover
  exit 0
fi

echo ""
printf "${CYAN}${BOLD}update-catalog-tags${RESET}  backend=${BACKEND}"
$DRY_RUN  && printf "  ${YELLOW}(dry-run)${RESET}"
$AUTO_YES && printf "  (auto-yes)"
echo ""
echo "Catalog: $CATALOG"

# collect items to process
ITEMS=$(python3 - "$CATALOG" "$TARGET" <<'PYEOF'
import json, sys
catalog = json.load(open(sys.argv[1]))
target = sys.argv[2]
for item in catalog['items']:
    if not target or item['id'] == target:
        print(json.dumps(item))
PYEOF
)

if [ -z "$ITEMS" ]; then
  echo "❌  No items found${TARGET:+ matching '$TARGET'}." >&2
  exit 1
fi

COUNT=$(echo "$ITEMS" | wc -l | tr -d ' ')
echo "Items to analyze: $COUNT"

while IFS= read -r item_json; do
  process_item "$item_json"
done <<< "$ITEMS"

echo ""
echo "──────────────────────────────────────────────────"
if $DRY_RUN; then
  echo "Dry-run complete. No files were modified."
elif [ "$CHANGED" -gt 0 ]; then
  printf "${GREEN}✅ Updated $CHANGED item(s) in $CATALOG${RESET}\n"
  echo "   Review changes with: git diff $CATALOG"
else
  echo "✅ No changes needed."
fi
