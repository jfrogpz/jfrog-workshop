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

Then run the initialization script:

```bash
bash automation/setup-event.sh \
  "2026-06-shanghai" \
  "JFrog Workshop Shanghai 2026"
```

The script will:
- Create the `workshop-events` Generic repository in Artifactory (if it doesn't exist)
- Upload the event configuration `config.json`
- Output the complete command to start the leaderboard

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

```
========================================================================
  🏆  JFrog Workshop Leaderboard   Event: 2026-06-shanghai
  🕐  Updated: 2026-06-22 10:30:00
========================================================================
  Rank  Nickname                 T1  T2  T3  T4  T5  T6   Score
------------------------------------------------------------------------
  🥇   alex                   ✅  ✅  ✅  ⬜  ⬜  ⬜    50pts
  🥈   mary-chen              ✅  ✅  ⬜  ⬜  ⬜  ⬜    30pts
  🥉   bob                    ✅  ⬜  ⬜  ⬜  ⬜  ⬜    10pts
------------------------------------------------------------------------
  3 participants
========================================================================
```

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

1. **Confirm Curation is enabled**: Log in to JFrog UI → Curation, confirm the feature is enabled and supports npm
2. **Run through the full flow**: Using a test environment, simulate a participant completing all T1–T6 tasks and confirm each task's verification logic works correctly — avoid surprises on the day

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
| Curation not blocking axios@1.7.2 | Confirm the participant's Curation Policy is Active, **Enforce policy on cached packages** is enabled under Policy Action, and Apply to is set to the remote repository (not virtual) |

---

## Customizing Event Configuration

To adjust task point values, edit the `tasks` array in `automation/setup-event.sh`, then re-run the initialization script to overwrite `config.json`:

```bash
bash automation/setup-event.sh "2026-06-shanghai" "JFrog Workshop Shanghai 2026"
```

---

## Architecture Notes

### Why GitHub Codespace as the Participant Environment

| Problem | Codespace Solution |
|---------|--------------------|
| Participants have different environments (Windows/Mac/Linux) | A unified cloud Linux environment, ready out of the box |
| Requires Node.js, JFrog CLI, bash pre-installed | `.devcontainer` auto-configures everything — participants install nothing manually |
| Sample project needs to be cloned | Codespace auto-checks out at startup; path is always `/workspaces/jfrog-workshop/` |
| AI guidance needed to lower the barrier | GitHub Copilot Chat is embedded directly in the IDE, reading `.github/copilot-instructions.md` as the task script |

Participants who don't use Codespace need to set up the environment manually — see [SETUP.md](SETUP.md).

---

### How Scoring and the Leaderboard Work

**Participant Registration (T1)**:
- The participant runs `register.sh`, which creates three npm repositories in Artifactory (local / remote / virtual) and writes an initial `progress.json` to the `workshop-events` repository (T1 marked as done, 10 points)
- After successful registration, the script writes `~/.workshop-profile` locally, storing the nickname, event ID, JFrog URL, and token — all subsequent scripts (`check-progress.sh`, `clear-remote-cache.sh`, etc.) read from this file, so credentials don't need to be entered again

**Task Verification (T2–T6)**:
- **Verification happens on the participant side**: After completing each task, participants run `check-progress.sh`, which automatically verifies completion via Artifactory/Xray REST APIs and updates progress
- Completed tasks are marked `done` and progress is uploaded to the `workshop-events` repository for the leaderboard to read
- Already-completed tasks are not re-verified — only pending tasks are checked

| Task | Verification Method |
|------|---------------------|
| T1 | `GET /api/repositories/{nickname}-npm-dev-virtual` returns 200 |
| T2 | `GET /api/storage/{nickname}-npm-org-remote` has subdirectories (cached packages present) |
| T3 | `GET /api/build/{nickname}-npm-sample/1` returns 200 |
| T4 | `GET /xray/api/v1/curation/policies` list contains a Policy with the participant's nickname |
| T5 | `GET /xray/api/v1/curation/audit/packages` contains a record of axios@1.7.2 being blocked for the participant's repository |
| T6 | Build #3 exists and axios in its dependencies is not version 1.7.2 |

**Leaderboard Rendering**:
- The organizer runs `refresh-leaderboard.sh`, which every 30 seconds **reads only** all participants' uploaded `progress.json` — no verification is performed
- Sorted by total score descending; ties broken by the time of the last completed task (ascending)
- The organizer projects this terminal window; participants can see it in real time

> **Note**: The leaderboard reflects progress from the last time a participant ran `check-progress.sh`. Participants must actively run the script after completing a task to update their progress.

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
