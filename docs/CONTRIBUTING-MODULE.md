# How to Add a New Workshop Module

> 🌐 [中文版](./CONTRIBUTING-MODULE_CN.md)

This document is designed to be used with an AI assistant (e.g. GitHub Copilot Chat) to develop new workshop modules — share this document with the AI and describe the module you want to build.

This guide explains how to create a new learning module for the JFrog Workshop. Each module is a self-contained unit with its own task definitions, verification logic, sample project, and AI guide.

---

## Module Directory Structure

Create a new directory under `modules/` named after your module (use lowercase letters, numbers, and hyphens):

```
modules/
└── <module-name>/
    ├── tasks.json            # Task definitions (required)
    ├── verify-tasks.sh       # Task verification functions (required)
    ├── create-repo.sh        # Artifactory repository setup (optional)
    ├── install-tools.sh      # Tool installation/verification (required)
    └── sample-project/       # Sample project for participants (required)

.github/instructions/
├── <module-name>.instructions.md      # Copilot Chat AI guide (required)
└── <module-name>.instructions-cn.md  # Chinese reading guide for participants without an AI assistant (optional)
```

The AI guide lives in `.github/instructions/`. It is loaded in two ways:
- **Auto-load**: the `applyTo: "modules/<module-name>/**"` frontmatter causes Copilot Chat to load it automatically when a participant opens any file under `modules/<module-name>/` in the editor
- **Explicit load**: `copilot-instructions.md` instructs the AI to run `cat .github/instructions/<module-name>.instructions.md` when a participant selects a module — this works even when no file is open in the editor

**Naming convention**: Module names should describe the technology and focus area, e.g. `npm-security`, `npm-basic`, `pypi-curation`.

---

## Step 1: Define Tasks — `tasks.json`

Each task in the module must have a unique ID following the pattern `<module-name>-T<number>`.

```json
[
  {
    "id": "npm-security-T1",
    "name": "Create personal npm repositories in Artifactory",
    "name_cn": "在 Artifactory 中创建个人 npm 仓库",
    "points": 10,
    "hint": "Run: bash modules/npm-security/create-repo.sh <NICKNAME>",
    "hint_cn": "运行：bash modules/npm-security/create-repo.sh <NICKNAME>"
  },
  {
    "id": "npm-security-T2",
    "name": "Complete first npm build",
    "name_cn": "完成首次 npm build",
    "points": 20,
    "hint": "cd modules/npm-security/sample-project, configure npm to use your virtual repo, then run: jf npm install --build-name=<NICKNAME>-npm-sample --build-number=1",
    "hint_cn": "进入 modules/npm-security/sample-project，配置 npm 指向你的虚拟仓库，然后运行：jf npm install --build-name=<NICKNAME>-npm-sample --build-number=1"
  }
]
```

**Rules**:
- Task IDs must be unique across **all** modules (use module prefix to guarantee this)
- The **first task** is typically the **create-repositories** task — `register.sh` automatically marks it `done` upon registration
- `points` values are flexible — no fixed total required
- `hint` and `hint_cn` are shown in `check-and-update-progress.sh` output to help participants who are stuck

---

## Create Artifactory Repositories — `create-repo.sh` (optional)

If your module requires Artifactory repositories, create `create-repo.sh`. Refer to `modules/npm-security/create-repo.sh` as a reference.

---

## Step 2: Write Verification Functions — `verify-tasks.sh`

Each task needs a verification function named `verify_<task_id_with_hyphens_replaced_by_underscores>`.

`check-and-update-progress.sh` calls these dynamically: task ID `npm-basic-T2` → function `verify_npm_basic_T2`.

```bash
#!/bin/bash
# <module-name> module: task verification functions
# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller

verify_npm_basic_T1() {
  # Verify repository creation: check that the virtual npm repository exists
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-npm-dev-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_npm_basic_T2() {
  # Verify first npm publish: check that the remote cache has children
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-npm-remote" 2>/dev/null \
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

## Step 3: Add a Sample Project — `sample-project/`

Place the participant's starting project files here. Requirements:
- Must be a runnable project for the target package type
- Should have at least one dependency that can be used to demonstrate the workshop's security scenario
- Keep it minimal — participants shouldn't need to understand the project code

---

## Step 4: Declare Tool Requirements — `install-tools.sh`

This script is called by `.devcontainer/post-create.sh` when the Codespace starts. Refer to `modules/npm-security/install-tools.sh` as a reference. The script should check for required tools, install if missing, and exit non-zero on failure.

---

## Step 5: Write the AI Guide — `.github/instructions/<module-name>.instructions.md`

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
- Each task section must use the full task ID as the heading (e.g. `### npm-basic-T2`)
- Include a **Module Overview** table with task IDs, descriptions, points, and verification criteria
- Include complete, copy-pasteable commands with `<NICKNAME>` as a placeholder
- List module prerequisites (e.g. Curation enabled, Xray configured) so organizers know what to prepare

You may also create an optional `<module-name>.instructions-cn.md` as a Chinese reading guide for participants who do not have Copilot. This file does **not** need `applyTo` frontmatter — it is intended for manual reading only.

---

## Step 6: Register the Module in an Event

Once your module is ready, include it when initializing an event:

```bash
bash automation/setup-event.sh \
  "2026-07-beijing" \
  "JFrog Workshop Beijing" \
  --modules npm-security,npm-basic
```

Or test it standalone:

```bash
bash automation/setup-event.sh \
  "2026-07-test" \
  "Module Test" \
  --modules npm-basic
```
