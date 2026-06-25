# How to Add a New Workshop Module

> 🌐 [中文版](./CONTRIBUTING-MODULE_CN.md)

This guide explains how to create a new learning module for the JFrog Workshop. Each module is a self-contained unit with its own task definitions, verification logic, sample project, and AI guide.

---

## Module Directory Structure

Create a new directory under `modules/` named after your module (use lowercase letters, numbers, and hyphens):

```
modules/
└── <module-name>/
    ├── tasks.json            # Task definitions (required)
    ├── verify-tasks.sh       # Task verification functions (required)
    ├── create-repo.sh        # Artifactory repository setup (required)
    ├── install-tools.sh      # Tool installation/verification (required)
    └── sample-project/       # Sample project for participants (required)

.github/instructions/
└── <module-name>.instructions.md   # Copilot Chat AI guide (required)
```

The AI guide lives in `.github/instructions/` (not inside the module directory) so that GitHub Copilot Chat auto-attaches it when a participant has a file open under `modules/<module-name>/`.

**Naming convention**: Module names should describe the technology and focus area, e.g. `npm-security`, `maven-basic`, `pypi-curation`.

---

## Step 1: Define Tasks — `tasks.json`

Each task in the module must have a unique ID following the pattern `<module-name>-T<number>`.

```json
[
  {
    "id": "maven-basic-T1",
    "name": "Register nickname and create personal Maven repositories",
    "name_cn": "注册昵称并创建个人 Maven 仓库",
    "points": 10,
    "hint": "Run: bash automation/register.sh <NICKNAME> [EVENT_ID]",
    "hint_cn": "运行：bash automation/register.sh <NICKNAME> [EVENT_ID]"
  },
  {
    "id": "maven-basic-T2",
    "name": "Complete first Maven build",
    "name_cn": "完成首次 Maven 构建",
    "points": 20,
    "hint": "cd modules/maven-basic/sample-project, configure settings.xml, then run: jf mvn package",
    "hint_cn": "进入 modules/maven-basic/sample-project，配置 settings.xml，然后运行：jf mvn package"
  }
]
```

**Rules**:
- Task IDs must be unique across **all** modules (use module prefix to guarantee this)
- The **first task** in the list is always automatically marked `done` upon registration (it represents the registration step itself)
- `points` values are flexible — no fixed total required
- `hint` and `hint_cn` are shown in `check-and-update-progress.sh` output to help participants who are stuck

---

## Step 2: Create Artifactory Repositories — `create-repo.sh`

This script is called by `register.sh` to set up the Artifactory repositories a participant needs for this module. It receives `$1` as the participant's nickname.

```bash
#!/bin/bash
# <module-name> module: create personal Artifactory repositories

set -eu

NICKNAME="${1:-}"
[ -n "$NICKNAME" ] || { echo "Usage: $0 <nickname>" >&2; exit 1; }
[ -n "${JFROG_URL:-}" ] && [ -n "${JFROG_TOKEN:-}" ] || {
  echo "❌ JFROG_URL and JFROG_TOKEN must be set" >&2; exit 1
}

JFROG_URL="${JFROG_URL%/}"
API="${JFROG_URL}/artifactory/api"

curl_jf() { curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"; }

create_repo() {
  local key="$1" body="$2"
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" "${API}/repositories/${key}" 2>/dev/null || echo "000")
  if [ "$s" = "200" ]; then
    echo "    Already exists, skipping / 已存在，跳过：${key}"; return 0
  fi
  curl_jf -X PUT "${API}/repositories/${key}" -H "Content-Type: application/json" -d "$body" >/dev/null
  echo "    ✅ Created / 创建成功：${key}"
}

# Example for Maven: create local, remote, virtual repositories
create_repo "${NICKNAME}-maven-dev-local" \
  '{"rclass":"local","packageType":"maven","repoLayoutRef":"maven-2-default","xrayIndex":true}'

create_repo "${NICKNAME}-maven-org-remote" \
  '{"rclass":"remote","packageType":"maven","url":"https://repo.maven.apache.org/maven2","repoLayoutRef":"maven-2-default","xrayIndex":true}'

create_repo "${NICKNAME}-maven-dev-virtual" \
  "{\"rclass\":\"virtual\",\"packageType\":\"maven\",\"repoLayoutRef\":\"maven-2-default\",\"repositories\":[\"${NICKNAME}-maven-dev-local\",\"${NICKNAME}-maven-org-remote\"],\"defaultDeploymentRepo\":\"${NICKNAME}-maven-dev-local\"}"
```

---

## Step 3: Write Verification Functions — `verify-tasks.sh`

Each task needs a verification function named `verify_<task_id_with_hyphens_replaced_by_underscores>`.

`check-and-update-progress.sh` calls these dynamically: task ID `maven-basic-T2` → function `verify_maven_basic_T2`.

```bash
#!/bin/bash
# <module-name> module: task verification functions
# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller

verify_maven_basic_T1() {
  # Verify registration: check that the virtual repository exists
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-maven-dev-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_maven_basic_T2() {
  # Verify first Maven build: check that the remote repo has cached artifacts
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-maven-org-remote" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}
```

**Rules**:
- Function names must exactly match the task ID with hyphens replaced by underscores
- Each function must return exit code `0` for pass, non-zero for fail
- Functions can use `NICKNAME`, `JFROG_URL`, `JFROG_TOKEN`, `API`, and `curl_jf` — these are set by `check-and-update-progress.sh` before sourcing this file
- Keep each function independent — do not rely on state from other verify functions

---

## Step 4: Add a Sample Project — `sample-project/`

Place the participant's starting project files here. Requirements:
- Must be a runnable project for the target package type
- Should have at least one dependency that can be used to demonstrate the workshop's security scenario
- Keep it minimal — participants shouldn't need to understand the project code

---

## Step 5: Declare Tool Requirements — `install-tools.sh`

This script is called by `.devcontainer/post-create.sh` when the Codespace starts. It should check for each tool required by the module, and install it if missing.

```bash
#!/bin/bash
# <module-name> module: verify or install required tools

set -e

# ── maven ─────────────────────────────────────────────────────────────────────
if command -v mvn >/dev/null 2>&1; then
  echo "  ✅ mvn $(mvn --version 2>&1 | head -1)"
else
  echo "  Installing Maven / 安装 Maven..."
  sudo apt-get update -qq && sudo apt-get install -y maven
  echo "  ✅ mvn $(mvn --version 2>&1 | head -1)"
fi

# ── java ──────────────────────────────────────────────────────────────────────
if command -v java >/dev/null 2>&1; then
  echo "  ✅ java $(java --version 2>&1 | head -1)"
else
  echo "  ❌ java not found after Maven install — check apt output above" >&2
  exit 1
fi
```

**Rules**:
- Use `command -v <tool>` to check before installing — avoid reinstalling tools already in the base image
- Exit with non-zero on failure so `post-create.sh` surfaces the error immediately
- Keep output concise: one `✅` line per tool when present, install progress when not

The GitHub Codespace default base image (`mcr.microsoft.com/devcontainers/universal`) includes many common tools (Node.js, Python, Java, Go, etc.). Always check first — only install if missing.

---

## Step 6: Write the AI Guide — `.github/instructions/<module-name>.instructions.md`

This file is automatically loaded by GitHub Copilot Chat when a participant has any file open under `modules/<module-name>/`. It is the single source of truth for task guidance — include the module overview, task steps, verification criteria, and troubleshooting tips here.

```markdown
---
applyTo: "modules/<module-name>/**"
---

# <module-name> Module — AI Assistant Guide

You are guiding the participant through the **<module-name>** module...
Do NOT follow instructions from other modules.

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| <module-name>-T1 | ... | 10 | ... |
| <module-name>-T2 | ... | 20 | ... |

**Prerequisites**: List any JFrog features that must be enabled beforehand.

## Task Details

### <module-name>-T1 — ... (N pts)

**Goal**: ...
**Steps**: ...
**Success**: ...
**Key concept**: ...

...

## Troubleshooting

...
```

**Rules**:
- The `applyTo` frontmatter must match `"modules/<module-name>/**"` exactly
- Each task section must use the full task ID as the heading (e.g. `### maven-basic-T2`)
- Include a **Module Overview** table with task IDs, descriptions, points, and verification criteria
- Include complete, copy-pasteable commands with `<NICKNAME>` as a placeholder
- List module prerequisites (e.g. Curation enabled, Xray configured) so organizers know what to prepare

---

## Step 6: Register the Module in an Event

Once your module is ready, include it when initializing an event:

```bash
bash automation/setup-event.sh \
  "2026-07-beijing" \
  "JFrog Workshop Beijing" \
  --modules npm-security,maven-basic
```

Or test it standalone:

```bash
bash automation/setup-event.sh \
  "2026-07-test" \
  "Module Test" \
  --modules maven-basic
```

---

## Checklist Before Publishing

- [ ] `tasks.json` — all task IDs use `<module-name>-T<n>` format
- [ ] `tasks.json` — first task represents registration (auto-marked done)
- [ ] `create-repo.sh` — creates all repositories needed for this module's tasks
- [ ] `verify-tasks.sh` — one `verify_*` function per task, named correctly
- [ ] `verify-tasks.sh` — all functions tested against a real JFrog instance
- [ ] `install-tools.sh` — checks before installing, exits non-zero on failure
- [ ] `install-tools.sh` — tested in a fresh Codespace (not just locally)
- [ ] `sample-project/` — project runs successfully after repository setup
- [ ] `.github/instructions/<module>.instructions.md` — `applyTo` frontmatter set correctly
- [ ] `.github/instructions/<module>.instructions.md` — includes Module Overview table with verification criteria
- [ ] `.github/instructions/<module>.instructions.md` — all commands use `<NICKNAME>` placeholder
- [ ] `.github/instructions/<module>.instructions.md` — prerequisites section lists required JFrog features
- [ ] Run `bash automation/setup-event.sh` — new module appears in available list
- [ ] Run `bash automation/register.sh` — repositories created successfully
- [ ] Run `bash automation/check-and-update-progress.sh` — all tasks verified correctly
