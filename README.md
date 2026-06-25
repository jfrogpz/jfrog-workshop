# NPM Supply Chain Security Workshop

> 🌐 [中文版](./README_CN.md)

This Workshop has three key features:

- **Ready out of the box**: Built on GitHub Codespace — no local tool installation required, just click to enter a unified cloud development environment
- **AI-guided learning**: Powered by GitHub Copilot Chat, the AI assistant guides you through every step — no prior JFrog knowledge needed
- **Competitive and fun**: Complete tasks to earn points in real time, with the instructor projecting a live leaderboard

---

## Background: npm Supply Chain Attacks

Supply chain attacks have become one of the most insidious threats facing developers today:

- **ua-parser-js (2021)**: The npm account was hijacked and three versions were injected with a cryptominer and credential stealer, affecting users globally within hours
- **PyTorch (2022)**: A malicious package entered via a dependency confusion attack, exfiltrating sensitive data
- **polyfill.io (2024)**: After cdn.polyfill.io's domain was acquired, the CDN began serving malicious scripts to over 100,000 websites — with affected sites completely unaware
- **lottie-player (2024)**: The npm package maintainer's account was hijacked, and a malicious version was automatically pushed to all dependents, planting a crypto wallet stealer
- **tj-actions/changed-files (2025)**: A widely-used GitHub Actions component was backdoored, causing a large number of CI/CD pipelines to leak secrets

The common thread: **developers unknowingly introduced malicious code into their production environments**.

---

## Who Is Affected? How Does JFrog Help?

### Affected Roles

| Role | Pain Point |
|------|------------|
| **Developers** | Don't know if the packages they use are safe; can't assess impact when fixing vulnerabilities |
| **Security Teams** | Can't intercept packages before they enter builds; can only scan after the fact |
| **DevOps / Platform Teams** | No unified artifact governance; hard to trace "who used which version" |

### JFrog's Solution

- **JFrog Artifactory**: A unified artifact proxy — all dependencies must flow through Artifactory repositories, forming a "moat"
- **JFrog Curation**: Automatically blocks known malicious packages and high-risk vulnerabilities at the **download stage** — one step earlier than post-build scanning
- **JFrog Xray**: Deep scanning of existing artifacts and build-info, providing CVE analysis and license compliance checks
- **Build Info**: Records the complete dependency tree of every build, enabling rapid traceability and impact analysis

📖 Learn more: [JFrog Curation Docs](https://jfrog.com/help/r/jfrog-curation) | [JFrog Xray Docs](https://jfrog.com/help/r/jfrog-xray)

---

## This Workshop

### Goal
Hands-on practice experiencing the complete supply chain security cycle: from "introducing a malicious dependency" to "detect → block → fix".

### Duration
Approximately 60 minutes

### Competition Rules

| Task | Description | Points |
|------|-------------|--------|
| T1 | Register a nickname and create personal Artifactory repositories | 10 |
| T2 | Complete the first npm build | 20 |
| T3 | Publish Build #1 build-info | 20 |
| T4 | Create a Curation Policy | 10 |
| T5 | Trigger Curation to block axios@1.7.2 | 20 |
| T6 | Fix the issue and complete Build #3 | 20 |
| **Total** | | **100** |

Ties are broken by the time the last task was completed (earlier is better).

### Prize
> To be announced by the instructor on the day 🎁

---

## Quick Start

### Step 1: Open in GitHub Codespace

Click the button below to launch the cloud development environment instantly (no local tool installation needed):

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/alexwang66/jfrog-workshop)

> ⏱️ First-time Codespace startup takes about 1–2 minutes — please be patient.
>
> 🆓 GitHub personal accounts get 60 free Codespace hours per month. This Workshop uses approximately 1 hour.
>
> 💻 **If Codespace is not available**, refer to [SETUP.md](./SETUP.md) to set up the environment on your local machine.

### Step 2: Open AI Assistant

Once Codespace is ready, the **GitHub Copilot Chat** panel is embedded on the **right side** of the window — type your message directly.

> 🤖 **If Copilot Chat is unavailable**, you can read [.github/copilot-instructions.md](.github/copilot-instructions.md) directly — it contains complete step-by-step instructions for all tasks.

### Step 3: Start the Workshop

Type one of the following in the Copilot Chat panel:

```
# Joining an event (with an instructor)
I want to start the workshop, my EVENT_ID is <ID provided by instructor>

# Self-study (no instructor or EVENT_ID needed)
I want to self-study
```

The AI assistant will guide you through all tasks, including logging in to JFrog UI to generate your personal token and registering your nickname. Event mode uses the instructor-provided admin account; self-study mode uses your own account.

> 💡 **Tip**: All commands are provided by the AI assistant — just paste them into the terminal.
>
> 📊 **Leaderboard** (event mode): The instructor will project the leaderboard, which refreshes every 30 seconds. No leaderboard in self-study mode.

---

## Task Overview

Here is a brief description of all 6 tasks (exact commands are provided by the AI assistant during the conversation):

| Task | Description | Verification |
|------|-------------|--------------|
| **T1 Register** | Choose a unique nickname; the script automatically creates your personal npm repository group on Artifactory (local / remote / virtual) | Artifactory contains a `{nickname}-npm-dev-virtual` repository |
| **T2 First Install** | Configure JFrog CLI to point to your Artifactory virtual repository, run `jf npm install` | `{nickname}-npm-org-remote` repository contains cached packages |
| **T3 Publish Build Info** | Publish the complete dependency information of your build to Artifactory for traceability | Artifactory contains Build `{nickname}-npm-sample #1` |
| **T4 Create Security Policy** | Create a Curation policy targeting your personal Artifactory repository to block risky npm packages; name must include your nickname | A Curation Policy with your nickname in its name exists in the policy list |
| **T5 Trigger Block** | Add `axios@1.7.2` (simulated malicious version) to the project, run `jf npm install`, observe Curation blocking it | Curation audit log contains a record of `axios@1.7.2` being blocked for your repository |
| **T6 Fix Issue** | Replace axios with a safe version, re-run `jf npm install`, and publish Build #3 | Artifactory contains Build `{nickname}-npm-sample #3` with an axios version other than `1.7.2` |

---

## Organizer Guide

If you are an instructor or event organizer, please refer to:

👉 [ORGANIZER.md](./ORGANIZER.md)
