# Organizer's Guide

> 🌐 [中文版](./ORGANIZER_CN.md)

This document is for instructors and event organizers, explaining how to prepare and run the JFrog Workshop.

> If you are not running a competitive event, participants can self-study directly — **no organizer setup is required**. This document only applies to events that use a leaderboard.

---

## Prerequisites

| Item | Requirement |
|------|-------------|
| JFrog Instance | JFrog Cloud (SaaS), domain format `xxx.jfrog.io` |
| Admin Token | Access Token with permissions to create Artifactory repositories, manage permissions, and read build-info |
| Number of Participants | No hard limit; recommended ≤ 50 (Codespace concurrency) |

---

## Step 1: Open Codespace (Organizer)

Open this GitHub repository page, click **Code → Codespaces → New codespace**, and wait for the environment to be ready.

---

## Step 2: Set Environment Variables and Initialize the Event

Set environment variables in the terminal (**only needs to be done once per session** — all subsequent scripts will read these):

```bash
export JFROG_TOKEN="your-admin-token"
export JFROG_URL="https://yourcompany.jfrog.io"
```

To see which modules are currently available, run the script with no arguments:

```bash
bash automation/setup-event.sh
```

Then run the initialization script, specifying which learning modules to include:

```bash
bash automation/setup-event.sh \
  "2026-06-shanghai" \
  "JFrog Workshop Shanghai 2026" \
  --modules npm-security
```

To include multiple modules in one event:

```bash
bash automation/setup-event.sh \
  "2026-06-shanghai" \
  "JFrog Workshop Shanghai 2026" \
  --modules npm-security,npm-basic
```

The script will:
- Validate that all specified modules exist under `modules/`
- Create the `workshop-events` Generic repository in Artifactory (if it doesn't exist)
- Upload the event configuration `config.json` (with tasks aggregated from all specified modules)
- Output the complete command to start the leaderboard

### Adding a Module to a Running Event

Re-run the script with the full updated module list at any time — it overwrites `config.json` with the combined task set. Existing participants' completed tasks are unaffected; the leaderboard will show the new module column on the next refresh.

```bash
bash automation/setup-event.sh \
  "2026-06-shanghai" \
  "JFrog Workshop Shanghai 2026" \
  --modules npm-security,npm-basic
```

> **Note**: Participants already registered will need to run the new module's `create-repo.sh` manually before starting its tasks, since repository creation only happens at registration time for the modules active at that moment.

---

## Step 3: Start the Leaderboard

Run the following command in the terminal (**keep it running throughout the Workshop and project this terminal window**):

```bash
# JFROG_TOKEN and JFROG_URL were already set in Step 2 — no need to set them again
bash automation/refresh-leaderboard.sh "2026-06-shanghai"
```

The script automatically every 30 seconds:
- Reads all participants' progress from Artifactory
- Clears the screen and refreshes the leaderboard

Press `Ctrl+C` to stop. Example leaderboard output:

Single-module event (`--modules npm-security`):

```
==============================================================
  🏆  JFrog Workshop  |  Event ID / 赛事 ID：2026-06-shanghai
  🕐  Updated / 更新时间：2026-06-22 10:30:00  |  Max / 满分：100 pts
==============================================================

  [npm-security]  (max: 100 pts)
  Rank Nickname / 昵称         T1  T2  T3  T4  T5  T6    Pts
  ------------------------------------------------------------
  🥇   alex                  ✅  ✅  ✅  ⬜  ⬜  ⬜   30pts
  🥈   mary-chen             ✅  ✅  ⬜  ⬜  ⬜  ⬜   20pts
  🥉   bob                   ✅  ⬜  ⬜  ⬜  ⬜  ⬜   10pts
  ------------------------------------------------------------

  [Summary / 汇总]
  Rank Nickname / 昵称                            Total
  ------------------------------------------------------------
  🥇   alex                                      30pts
  🥈   mary-chen                                 20pts
  🥉   bob                                       10pts
  ------------------------------------------------------------
  3 participants / 名学员参赛
==============================================================
```

Multi-module event (`--modules npm-security,npm-basic`), each module has its own ranked block:

```
==============================================================
  🏆  JFrog Workshop  |  Event ID / 赛事 ID：2026-06-shanghai
  🕐  Updated / 更新时间：2026-06-22 10:30:00  |  Max / 满分：160 pts
==============================================================

  [npm-security]  (max: 100 pts)
  Rank Nickname / 昵称         T1  T2  T3  T4  T5  T6    Pts
  ------------------------------------------------------------
  🥇   alex                  ✅  ✅  ✅  ⬜  ⬜  ⬜   30pts
  🥈   mary-chen             ✅  ✅  ⬜  ⬜  ⬜  ⬜   20pts
  ------------------------------------------------------------

  [npm-basic]  (max: 60 pts)
  Rank Nickname / 昵称         T1  T2  T3    Pts
  -----------------------------------------------
  🥇   mary-chen             ✅  ✅  ⬜   30pts
  🥈   alex                  ✅  ⬜  ⬜   10pts
  -----------------------------------------------

  [Overall / 总排行]
  Rank Nickname / 昵称                            Total
  ------------------------------------------------------------
  🥇   mary-chen                                 50pts
  🥈   alex                                      40pts
  ------------------------------------------------------------
  2 participants / 名学员参赛
==============================================================
```

> **Note**: Column labels show the last segment of the task ID (e.g. `npm-security-T1` → `T1`). Each module block ranks participants independently by their module score.

---

## Step 4: Share the Following Information with Participants

Before starting, provide all participants with:

| Information | Value |
|-------------|-------|
| JFROG_URL | `https://yourcompany.jfrog.io` (the value of `$JFROG_URL`) |
| Admin Username | JFrog admin username (participants use this to log in to JFrog UI) |
| Admin Password | JFrog admin password |
| EVENT_ID | `2026-06-shanghai` (the value you set) |
| How to start | Open Codespace → in the embedded Copilot Chat on the right, type "I want to start the workshop, my EVENT_ID is xxx" |

> **Note**: All participants share the same admin account to log in to JFrog UI. After logging in, each generates their own token under **Edit Profile → Access Tokens**. Individual tokens are independent and won't conflict. It is recommended to change the admin password after the Workshop.

---

## Pre-Event Checklist

Confirm the following before the event starts:

1. **Verify module prerequisites**: Check the module(s) you selected require specific JFrog features (e.g. Curation, Xray). Refer to each module's `instructions.md` or the module author's notes for what needs to be enabled in JFrog UI beforehand
2. **Run through the full flow**: Using a test environment, simulate a participant completing all tasks in the active module(s) and confirm each task's verification logic works correctly — avoid surprises on the day

---

## Post-Event Cleanup

### Clean up a single participant

```bash
# JFROG_TOKEN and JFROG_URL were already set in Step 2
bash automation/delete-repo.sh <nickname> all --event-id "2026-06-shanghai"
```

### Bulk cleanup of all participants

```bash
# List all registered participants (requires JFROG_TOKEN and JFROG_URL to be set)
curl -s -H "Authorization: Bearer $JFROG_TOKEN" \
  "${JFROG_URL}/artifactory/api/storage/workshop-events/2026-06-shanghai/participants" \
  | python3 -c "import sys,json; [print(c['uri'].strip('/')) for c in json.load(sys.stdin).get('children',[])]"

# Run delete-repo.sh for each participant
```

### Delete the entire event data

Delete the `workshop-events/2026-06-shanghai/` directory in the Artifactory UI.

---

## Troubleshooting

| Problem | How to Investigate |
|---------|--------------------|
| Leaderboard shows no participants | Check if the `workshop-events/{event_id}/participants/` directory has data in Artifactory |
| Participant tasks not updating | Confirm `refresh-leaderboard.sh` is running; check if the Admin Token is still valid |
| Module-specific feature not working | Refer to the module's `.github/instructions/<module>.instructions.md` for troubleshooting tips specific to that module |

---

## Customizing Event Configuration

To adjust task point values, edit the `tasks.json` file inside the relevant module directory (e.g. `modules/npm-security/tasks.json`), then re-run the initialization script to regenerate `config.json`:

```bash
bash automation/setup-event.sh "2026-06-shanghai" "JFrog Workshop Shanghai 2026" --modules npm-security
```

To add a new learning module to the workshop, see [CONTRIBUTING-MODULE.md](CONTRIBUTING-MODULE.md).

---

## Architecture Notes

### Why GitHub Codespace as the Participant Environment

| Problem | Codespace Solution |
|---------|--------------------|
| Participants have different environments (Windows/Mac/Linux) | A unified cloud Linux environment, ready out of the box |
| Requires Node.js, JFrog CLI, bash pre-installed | `.devcontainer` auto-configures everything — participants install nothing manually |
| Sample project needs to be cloned | Codespace auto-checks out at startup; path is always `/workspaces/jfrog-workshop/` |
| AI guidance needed to lower the barrier | GitHub Copilot Chat is embedded directly in the IDE, reading `.github/copilot-instructions.md` as the task script |

---

### How Scoring and the Leaderboard Work

**Participant Registration**:
- The participant runs `register.sh`, which reads the event's `config.json` to discover which modules are active, sets up the required resources, and writes an initial `progress.json`
- After successful registration, `~/.workshop-profile` is written locally — all subsequent scripts read from it so credentials don't need to be re-entered

**Task Verification**:
- **Verification happens on the participant side**: After completing each task, participants run `check-and-update-progress.sh`, which dynamically sources each module's `verify-tasks.sh` and dispatches to the matching `verify_<task_id>()` function
- Completed tasks are marked `done` and progress is uploaded to the `workshop-events` repository for the leaderboard to read
- Already-completed tasks are not re-verified — only pending tasks are checked

Task IDs use the format `<module>-<sequence>`, e.g. `npm-security-T1`. The verification logic for each task lives in `modules/<module>/verify-tasks.sh`. For task-level details, refer to the module's `.github/instructions/<module>.instructions.md`.

**Leaderboard Rendering**:
- The organizer runs `refresh-leaderboard.sh`, which every 30 seconds **reads only** all participants' uploaded `progress.json` — no verification is performed
- Sorted by total score descending; ties broken by the time of the last completed task (ascending)
- The organizer projects this terminal window; participants can see it in real time

> **Note**: The leaderboard reflects progress from the last time a participant ran `check-and-update-progress.sh`. Participants must actively run the script after completing a task to update their progress.

---

### Why Use Artifactory for Data Storage

- **Zero extra dependencies**: Participants are already working with Artifactory — no additional database or API service needed
- **Complete REST API**: Upload, download, and list directories all have standard APIs, drivable with bash + curl + python3
- **Visual debugging**: Organizers can view or modify any participant's JSON files directly in the Artifactory UI

```
Artifactory Generic Repository: workshop-events
│
└── {event_id}/                        # Event directory, e.g. 2026-06-shanghai
    ├── config.json                    # Event config (task points, timing, etc.)
    └── participants/
        └── {nickname}/                # One directory per participant
            ├── profile.json           # Participant info (nickname, registration time)
            └── progress.json          # Participant progress (task status and score)
```
