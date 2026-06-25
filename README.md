# JFrog Supply Chain Security Workshop

> 🌐 [中文版](./README_CN.md)

This Workshop has three key features:

- **Ready out of the box**: Built on GitHub Codespace — no local tool installation required, just click to enter a unified cloud development environment
- **AI-guided learning**: Powered by GitHub Copilot Chat, the AI assistant guides you through every step — no prior JFrog knowledge needed
- **Competitive and fun**: Complete tasks to earn points in real time, with the instructor projecting a live leaderboard

---

## Background: Software Supply Chain Attacks

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
Approximately 60 minutes per module

### Competition Rules

Tasks are organized into **modules** (e.g. `npm-security`, `npm-basic`). Each module has its own task list with individual point values. The instructor chooses which modules are active for the event.

- Complete tasks within the active module(s) to earn points
- Ties are broken by the time the last task was completed (earlier is better)
- Task details and commands are provided by the AI assistant during the session

### Prize
> To be announced by the instructor on the day 🎁

---

## Quick Start

### Step 1: Open in GitHub Codespace

Click the button below to launch the cloud development environment instantly (no local tool installation needed):

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/jfrogpz/jfrog-workshop)

> ⏱️ First-time Codespace startup takes about 1–2 minutes — please be patient.
>
> 🆓 GitHub personal accounts get 60 free Codespace hours per month. This Workshop uses approximately 1 hour.
>
> 💻 **If Codespace is not available**, refer to [SETUP.md](./docs/SETUP.md) to set up the environment on your local machine.

### Step 2: Open AI Assistant

Once Codespace is ready, the **GitHub Copilot Chat** panel is embedded on the **right side** of the window — type your message directly.

> 🤖 **If Copilot Chat is unavailable**, read the module instructions file directly — e.g. [.github/instructions/npm-security.instructions.md](.github/instructions/npm-security.instructions.md) — it contains complete step-by-step instructions for all tasks.

### Step 3: Start the Workshop

Type one of the following in the Copilot Chat panel:

```
# Self-study mode (no instructor or EVENT_ID needed)
I want to self-study

# Event mode (joining an instructor-led session)
I want to start the workshop, my EVENT_ID is <ID provided by instructor>

# Switching modules mid-session
I want to switch to the npm-basic module
```

The AI assistant will:
1. Guide you to log in to JFrog UI and generate your personal access token
2. Ask which module you want to learn
3. Walk you through each task step by step (check your progress, explain concepts, and help diagnose issues)

> 💡 **Tip**: All commands are provided by the AI assistant — just paste them into the terminal.
>
> 📊 **Leaderboard** (event mode only): The instructor will project the leaderboard, which refreshes every 30 seconds.

---

## Organizer Guide

If you are an instructor or event organizer, please refer to:

👉 [ORGANIZER.md](./docs/ORGANIZER.md)

To add a new learning module to the workshop:

👉 [CONTRIBUTING-MODULE.md](./docs/CONTRIBUTING-MODULE.md)
