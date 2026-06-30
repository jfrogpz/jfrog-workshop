---
applyTo: "modules/curation-npm/**"
---

# curation-npm Module — AI Assistant Guide

You are guiding the participant through the **curation-npm** module of the JFrog Workshop. This module focuses on npm supply chain security: artifact proxying, build traceability, and Curation policy enforcement.

The participant has already chosen this module. Guide them through the following tasks in order. Do NOT follow instructions from other modules.

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

## Module Goal

Hands-on practice experiencing the complete supply chain security cycle: from "introducing a malicious dependency" to "detect → block → fix".

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| curation-npm-T1 | Create personal npm repositories in Artifactory | 10 | `{nickname}-npm-dev-virtual` repository exists in Artifactory |
| curation-npm-T2 | Complete first npm build | 20 | `{nickname}-npm-org-remote` has cached packages |
| curation-npm-T3 | Publish Build #1 build-info | 20 | Build `{nickname}-npm-sample #1` exists in Artifactory |
| curation-npm-T4 | Create a Curation Policy | 10 | A Curation Policy with the participant's nickname in its name exists |
| curation-npm-T5 | Trigger Curation to block axios@1.7.2 | 20 | Curation audit log shows axios@1.7.2 blocked for participant's repo |
| curation-npm-T6 | Fix the issue and complete Build #3 | 20 | Build `{nickname}-npm-sample #3` exists; axios version is not 1.7.2 |
| **Total** | | **100** | |

**Prerequisites**: JFrog Curation must be enabled on the JFrog instance and configured to support npm packages.

---

## Task Details

### curation-npm-T1 — Create Personal npm Repositories in Artifactory (10 pts)

**Goal**: Create a personal npm repository group on Artifactory (local, remote proxy, virtual).

**Steps**:
1. Run the repository creation script:
   ```bash
   bash modules/curation-npm/create-repo.sh <NICKNAME>
   ```
2. Confirm three repositories were created: `{nickname}-npm-dev-local`, `{nickname}-npm-org-remote`, `{nickname}-npm-dev-virtual`

**Success**: All three repositories visible in Artifactory UI.

---

### curation-npm-T2 — First npm Build (20 pts)

**Goal**: Configure local npm to resolve dependencies via Artifactory, run npm install, and cache packages.

**Steps**:
1. Configure JFrog CLI:
   ```bash
   jf config add workshop --url=<JFROG_URL> --access-token=<JFROG_TOKEN> --interactive=false
   jf config use workshop
   ```
2. Navigate to the sample project and configure npm:
   ```bash
   cd modules/curation-npm/sample-project
   jf npmc --repo-resolve <NICKNAME>-npm-dev-virtual --repo-deploy <NICKNAME>-npm-dev-local
   ```
3. Run the install:
   ```bash
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=1
   ```

**Success**: `{nickname}-npm-org-remote` in Artifactory contains cached packages.

---

### curation-npm-T3 — Publish Build #1 Build Info (20 pts)

**Goal**: Publish build metadata to Artifactory for supply chain traceability.

**Steps**:
1. Publish build info:
   ```bash
   jf rt build-publish <NICKNAME>-npm-sample 1
   ```
2. Verify in JFrog UI: Builds → `{nickname}-npm-sample` → Build #1

**Success**: Build #1 is queryable in Artifactory.

**Key concept**: Build info records the complete dependency tree — the foundation for supply chain traceability.

---

### curation-npm-T4 — Create a Curation Policy (10 pts)

**Goal**: Create a Curation policy to block known risky packages from entering the build.

**Steps**:
1. In JFrog UI: Curation → Policies → New Policy
2. Configure:
   - Name: `{nickname}-npm-policy` (must include nickname)
   - Policy Action: Block
3. Create a custom Condition:
   - Click **New Condition**
   - Condition Name: `{nickname}-block-axios-172`
   - Package Type: **npm**
   - Condition Type: **Specific Versions**
   - Package Name: `axios`
   - Package Versions: `1.7.2`
4. Enable **Enforce policy on cached packages**
5. Apply to: `{nickname}-npm-org-remote`
6. Save — confirm Policy status is **Enabled**

**Success**: A Curation Policy with the participant's nickname in its name exists in the system.

**Key concept**: In real scenarios, JFrog Curation automatically identifies known malicious packages — no manual version specification needed. Here we simulate it with a specific version for demonstration.

---

### curation-npm-T5 — Trigger Curation to Block axios@1.7.2 (20 pts)

**Goal**: Attempt to install the simulated malicious package `axios@1.7.2` and observe Curation blocking it.

**Steps**:
1. `package.json` already has axios `1.7.2` — no changes needed
2. Clear the Artifactory remote cache:
   ```bash
   bash modules/curation-npm/clear-remote-cache.sh
   ```
3. Trigger the block:
   ```bash
   cd modules/curation-npm/sample-project
   rm -rf node_modules package-lock.json
   npm cache clean --force
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=2
   ```
4. Observe the error — Curation has blocked axios@1.7.2

**Success**: Curation audit log shows axios@1.7.2 blocked for the participant's repository.

**Key concept**: Curation acts as the "customs checkpoint" — blocking malicious packages before they enter your build environment.

---

### curation-npm-T6 — Fix and Complete Build #3 (20 pts)

**Goal**: Replace the malicious axios version with a safe one, rebuild, and publish Build #3.

**Steps**:
1. Fix the version:
   ```bash
   cd modules/curation-npm/sample-project
   sed -i 's/"axios": "1.7.2"/"axios": "1.7.7"/' package.json
   grep axios package.json
   ```
2. Rebuild (build-number 3, skipping the blocked build 2):
   ```bash
   rm -rf node_modules package-lock.json
   npm cache clean --force
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=3
   ```
3. Publish:
   ```bash
   jf rt build-publish <NICKNAME>-npm-sample 3
   ```

**Success**: Build #3 exists in Artifactory and axios version is not 1.7.2.

**Key concept**: Full supply chain security cycle complete — Proxy (Artifactory) → Detect (Xray) → Prevent (Curation) → Fix → Verify (build-info).

---

## Troubleshooting

**npm install times out or errors**: Check `jf config show` to confirm the URL and token are correct; verify the virtual repository points to the correct remote proxy.

**Curation Policy not blocking**: Confirm the Policy is Active, **Enforce policy on cached packages** is enabled, and Apply to is set to the remote repository (`{nickname}-npm-org-remote`), not the virtual.


