---
applyTo: "modules/xray-npm/**"
---

# xray-npm Module — AI Assistant Guide

You are guiding a participant through the **xray-npm** module of the JFrog Workshop. This module focuses on Xray vulnerability scanning: complete an npm build through Artifactory, publish Build Info, create an Xray Security Policy and Watch, then scan the build and explore CVE results.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Use JFrog Xray to scan npm dependencies for security vulnerabilities: configure a security policy to define CVE severity thresholds, create a Watch to associate resources with the policy, trigger scans on build artifacts, and review vulnerability details and remediation guidance in the UI.

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| xray-npm-T1 | Create personal npm repositories in Artifactory | 10 | `{nickname}-npm-xray-virtual` repo exists |
| xray-npm-T2 | Complete npm build and publish Build Info | 20 | `{nickname}-xray-npm-build/1` Build Info exists |
| xray-npm-T3 | Create an Xray Security Policy | 20 | Policy name contains nickname, type is Security |
| xray-npm-T4 | Create an Xray Watch targeting your build | 20 | Watch name contains nickname |
| xray-npm-T5 | Trigger Xray scan and explore CVE results | 20 | Manual verification (UI exploration) |
| **Total** | | **90** | |

**Prerequisites**: JFrog instance has Xray enabled with a valid license for npm scanning.

---

## Task Details

### xray-npm-T1 — Create Personal npm Repositories (10 pts)

**Goal**: Create three Xray-indexed npm repositories (local / remote / virtual).

**Steps**:

Confirm profile is loaded:
```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
```

Run:
```bash
bash modules/xray-npm/create-repo.sh $NICKNAME
```

Expected output:
```
Creating Artifactory repositories for <nickname> (xray-npm)...
    ✅ Created: <nickname>-npm-xray-local
    ✅ Created: <nickname>-npm-xray-remote
    ✅ Created: <nickname>-npm-xray-virtual
✅ Repositories ready for <nickname>
```

**Success indicator**: All three repositories visible in JFrog UI → Artifactory → Repositories with Xray indexing enabled.

---

### xray-npm-T2 — Complete npm Build and Publish Build Info (20 pts)

**Goal**: Run an npm install through Artifactory and publish Build Info so Xray can scan the dependencies.

**Steps**:

1. Configure JFrog CLI (skip if already done):
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

2. Configure npm to resolve through Artifactory:
   ```bash
   jf npmc --repo-resolve=${NICKNAME}-npm-xray-virtual --repo-deploy=${NICKNAME}-npm-xray-local
   ```

3. Navigate to the sample project and build:
   ```bash
   cd modules/xray-npm/sample-project
   jf npm install --build-name=${NICKNAME}-xray-npm-build --build-number=1
   ```

4. Publish Build Info:
   ```bash
   jf rt build-collect-env ${NICKNAME}-xray-npm-build 1
   jf rt build-publish ${NICKNAME}-xray-npm-build 1
   ```

**Success indicator**: Build record visible in Artifactory UI → Builds → `{nickname}-xray-npm-build`.

**Key concept**: Build Info contains the complete dependency manifest. Xray uses it to match package identifiers against its vulnerability database — without Build Info, Xray cannot associate vulnerabilities with your specific build.

---

### xray-npm-T3 — Create an Xray Security Policy (20 pts)

**Goal**: Create a Security-type Xray policy that defines rules for High and Critical CVEs.

**Steps**:

1. Open JFrog UI → Xray → Policies
2. Click **New Policy**
3. Fill in:
   - **Name**: `{NICKNAME}-security-policy` (name must contain your nickname)
   - **Type**: Security
4. Click **New Rule** and fill in:
   - **Rule Name**: `block-high-cve`
   - **Min Severity**: High
   - **Actions**: Block download (optional)
5. Save the policy

**Success indicator**: Policy visible in Xray → Policies list with your nickname in the name.

**Key concept**: An Xray policy defines *what counts as a violation*. The policy alone doesn't scan anything — it only takes effect when associated with a Watch that monitors specific resources.

---

### xray-npm-T4 — Create an Xray Watch Targeting Your Build (20 pts)

**Goal**: Create an Xray Watch that links your npm repositories to your security policy, enabling continuous monitoring.

**Steps**:

1. Open JFrog UI → Xray → Watches
2. Click **New Watch**
3. Fill in:
   - **Name**: `{NICKNAME}-npm-watch` (name must contain your nickname)
4. Under **Resources**, add:
   - **Repositories**: add `{NICKNAME}-npm-xray-local` and `{NICKNAME}-npm-xray-remote`
   - Or **Builds**: add `{NICKNAME}-xray-npm-build`
5. Under **Assigned Policies**, add `{NICKNAME}-security-policy`
6. Save the Watch

**Success indicator**: Watch visible in Xray → Watches list with your nickname in the name and policy attached.

**Key concept**: A Watch is the trigger — it connects "what to scan" (resources) with "how to judge" (policies). Once a Watch is created, Xray automatically scans any indexed artifacts within the watched resources.

---

### xray-npm-T5 — Trigger Xray Scan and Explore CVE Results (20 pts)

**Goal**: Trigger a scan (if needed) and explore the CVE report in the JFrog UI to understand the vulnerability details.

**Steps**:

1. Open JFrog UI → Xray → Scans List
2. Locate your build `{NICKNAME}-xray-npm-build`
3. Click in to explore:
   - **Violations**: which CVEs triggered your policy
   - **CVE Details**: CVSS score, affected versions, fixed versions
   - **Dependency Path**: which direct dependency introduced the vulnerability

Optionally trigger a scan explicitly:
```bash
jf rt build-scan ${NICKNAME}-xray-npm-build 1
```

**This task is manually verified — once you've explored the UI, run the progress check to claim the points.**

**Key concept**: `axios@1.7.2` has known CVEs visible in Xray scan results. The fix is to upgrade to `1.7.7` or later. Xray shows the dependency path so you know exactly which package to update.

---

## Troubleshooting

**Repo creation fails (401/403)**: Confirm `JFROG_URL` and `JFROG_TOKEN` are set; confirm the token has Manage Repositories or Admin permission.

**`jf npm install` returns 404**: Confirm `{nickname}-npm-xray-virtual` exists; confirm `jf npmc` was configured to point to that virtual repo.

**Build Info publish fails**: Confirm `jf npm install` was run with `--build-name` and `--build-number` — without these flags there is no build info to publish.

**Xray scan results are empty**: Xray indexing takes 1-3 minutes after publishing; confirm the repos have `xrayIndex: true` (the `create-repo.sh` script sets this automatically).

**Xray menu not visible**: Confirm the JFrog instance has an active Xray license; ask the instructor to verify the environment.
