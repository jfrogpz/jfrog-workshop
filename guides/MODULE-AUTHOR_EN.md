# JFrog Workshop — Module Author Guide

> 🌐 [中文版](./MODULE-AUTHOR.md)

This guide helps you develop new Workshop modules using AI. You describe what you need and review the output — AI generates all the files.

---

## How to Add a New Module

### Step 1: Describe the module to the AI

In Claude Code or Copilot Chat, describe what you want. Give enough information for the AI to make decisions:

```
Develop a new Workshop module called <module-name>:
- Goal: let participants experience <JFrog product/feature>
- Package type: npm / maven / docker / pypi
- Number of tasks: 5, total 90 points
- Key task flow: <rough description>
- Sample project: needs to include <specific dependencies/scenario>
```

The AI will generate all necessary files in order — task definitions, verification scripts, sample project, AI guide, and an update to the catalog page data.

### Step 2: Review the key files

After the AI generates the files, focus on:

- **tasks.json**: Does the task flow make sense? Do points reflect difficulty (T1 lowest)? Is the final UI exploration task marked `"verify": false`?
- **verify-tasks.sh**: Does each function name exactly match the task ID (hyphens → underscores)? Does the verification logic check that the task is truly complete, not just that the repository exists?
- **sample-project**: Can the project run as-is? Does a security module include suitable demo dependencies?
- **instructions.md**: Are commands complete and copy-pasteable? Does it cover common troubleshooting?

### Step 3: Tell the AI to adjust

State the problem directly — the AI will update the relevant file:

```
The T3 verification in verify-tasks.sh is not accurate enough.
It should check /xray/api/v2/policies for a policy name containing
the nickname — not just check if the repository has content.
```

---

## Directory Structure

```
modules/
└── <module-name>/
    ├── tasks.json            # Task definitions (required)
    ├── verify-tasks.sh       # Task verification functions (required)
    ├── sample-project/       # Participant starter project (usually needed)
    ├── create-repo.sh        # Create Artifactory repositories (usually needed)
    ├── install-tools.sh      # Tool check/installation (required)
    └── <other scripts>/      # Optional, e.g. clear-cache.sh

.github/instructions/
├── <module-name>.instructions.md      # AI guide (Chinese, required)
└── <module-name>.instructions-en.md  # AI guide (English, optional)
```

File roles and who calls them:

| File | Purpose | Called by |
|------|---------|-----------|
| `tasks.json` | Task list: IDs, names, points, hint text | `check-and-update-progress.sh`, catalog page |
| `verify-tasks.sh` | API verification logic per task | `check-and-update-progress.sh` via dynamic source |
| `sample-project/` | Example code participants work with directly | Participants |
| `create-repo.sh` | One-command creation of participant's Artifactory repos | Participants manually (given in T1 hint) |
| `install-tools.sh` | Check/install required tools | `post-create.sh` at Codespace startup |
| `<module-name>.instructions.md` | AI task steps, commands, verification, troubleshooting | Copilot Chat auto-loads; Claude Code explicit cat |

See real implementations for reference: [modules/](../modules/)

---

## Design Principles

### Naming convention

Module names typically follow the `<product-line>-<ecosystem>` pattern, but this is a suggestion rather than a rule.

Take `xray-npm` as an example: product line is `xray` (JFrog Xray vulnerability scanning), ecosystem is `npm`. Similarly, `curation-docker` is the Curation product + Docker ecosystem, and `ci-github-actions` is CI integration + GitHub Actions (no specific package ecosystem).

Browse all existing module names for reference: [Module Catalog](https://jfrogpz.github.io/jfrog-workshop/)

### Modules are self-contained — no prerequisites

Every module starts from scratch and assumes the participant has completed nothing else. Even if steps (like creating repositories) overlap with other modules, include them fully in T1/T2 of this module.

Reason: organizers can compose any combination of modules into an event, in any order.

### About task verification

Every task (except those marked `"verify": false` for UI exploration) must have a corresponding API-based verification method. **When designing a task, figure out first: how can I determine via REST API that this task is complete?** If you can't think of a clean verification approach, the task design itself may need adjustment.

Common verification patterns:

| What to verify | API |
|---------------|-----|
| Repository exists | `GET /artifactory/api/repositories/{repo}` → 200 |
| Build/install ran | `GET /artifactory/api/storage/{repo}` → `children` non-empty |
| Build Info published | `GET /artifactory/api/build/{name}/{number}` → 200 |
| Xray policy/watch created | `GET /xray/api/v2/policies` or `/watches`, match nickname in results |
| Curation policy created | `GET /xray/api/v1/curation/policies`, match nickname in results |

Tasks marked `"verify": false` (e.g. "view results in the UI") are auto-passed by the framework — the AI guide still walks participants through the steps, and points are awarded normally.

---

## AI Guide Files

`.github/instructions/<module-name>.instructions.md` is the script the AI assistant uses to guide participants through tasks. It is the single source of truth for task instructions.

**When creating a new module, reference an existing guide file as a template** — for example [xray-npm.instructions.md](../.github/instructions/xray-npm.instructions.md) — and ask the AI to follow the same structure and style.

Guide files are loaded in two ways:

- **Auto-load** (Copilot Chat): the `applyTo: "modules/<module-name>/**"` frontmatter injects the guide automatically whenever a participant opens any file in the module directory
- **Explicit load** (Claude Code): when a participant selects a module, Claude Code runs `cat .github/instructions/<module-name>.instructions.md`

Each task section heading must include the full task ID (e.g. `### xray-npm-T3`) — the AI uses this to match the participant's current progress. Use `$NICKNAME` in commands (sourced from `~/.workshop-profile`).

---

## Module Catalog Page

The [Module Catalog page](https://jfrogpz.github.io/jfrog-workshop/) is powered by `docs/module-catalog.json`. Authors don't need to maintain this file manually — **after each module development session, the AI updates it automatically**, including:

- Changing `status` from `coming-soon` to `available`
- Syncing the task list from `tasks.json` into the `tasks` array
- Analyzing module content and filling in `tags` (scenario / role / ecosystem)

To manually trigger a tag re-analysis, run `/update-tags` in Claude Code.

---

## Notes

**Cross-file consistency**: Whenever a concept (module ID, task ID, repository name, script parameter) is changed, it must be updated in every file where it appears, all in a single commit — partial commits create inconsistent intermediate states.

**Module status**: The `status` field is maintained only in `module-catalog.json`. No other file duplicates it.
