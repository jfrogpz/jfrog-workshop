---
applyTo: "modules/xray-docker/**"
---

# xray-docker Module — AI Assistant Guide

You are guiding a participant through the **xray-docker** module of the JFrog Workshop. This module focuses on container image security scanning: push a Docker image through Artifactory, publish Build Info, create an Xray Security Policy and Watch, then scan the image and explore CVE results including layer-level vulnerability breakdown.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Use JFrog Xray to scan container images for vulnerabilities: push a Docker image to Artifactory-managed registries, publish Build Info for traceability, configure a security policy and Watch, and review CVE details with layer-level attribution in the UI.

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| xray-docker-T1 | Create personal Docker repositories in Artifactory | 10 | `{nickname}-docker-xray-virtual` repo exists |
| xray-docker-T2 | Build and push Docker image through Artifactory | 20 | `{nickname}-docker-xray-local` has images |
| xray-docker-T3 | Publish Docker Build Info to Artifactory | 20 | `{nickname}-xray-docker-build/1` Build Info exists |
| xray-docker-T4 | Create an Xray Security Policy and Watch for Docker | 20 | Both policy and watch names contain nickname |
| xray-docker-T5 | View container image CVE scan results | 20 | Manual verification (UI exploration) |
| **Total** | | **90** | |

**Prerequisites**: JFrog instance has Xray enabled; Docker is installed locally; the JFrog instance domain is accessible for Docker push.

---

## Task Details

### xray-docker-T1 — Create Personal Docker Repositories (10 pts)

**Goal**: Create three Xray-indexed Docker repositories (local / remote / virtual).

**Steps**:

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/xray-docker/create-repo.sh $NICKNAME
```

Expected output:
```
Creating Artifactory repositories for <nickname> (xray-docker)...
    ✅ Created: <nickname>-docker-xray-local
    ✅ Created: <nickname>-docker-xray-remote
    ✅ Created: <nickname>-docker-xray-virtual
✅ Repositories ready for <nickname>
```

---

### xray-docker-T2 — Build and Push Docker Image Through Artifactory (20 pts)

**Goal**: Build the sample Docker image and push it to Artifactory using JFrog CLI to trigger Xray indexing.

**Steps**:

1. Configure JFrog CLI (skip if already done):
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

2. Log in to the Artifactory Docker registry:
   ```bash
   docker login ${JFROG_URL#https://} -u $NICKNAME -p $JFROG_TOKEN
   ```
   > Note: Docker login uses the domain without `https://`.

3. Build the image:
   ```bash
   cd modules/xray-docker/sample-project
   DOCKER_REGISTRY="${JFROG_URL#https://}/docker"
   docker build -t ${DOCKER_REGISTRY}/${NICKNAME}-docker-xray-local/xray-demo:1.0 .
   ```

4. Push via JFrog CLI (captures Build Info):
   ```bash
   jf docker push ${DOCKER_REGISTRY}/${NICKNAME}-docker-xray-local/xray-demo:1.0 \
     --build-name=${NICKNAME}-xray-docker-build \
     --build-number=1
   ```

**Success indicator**: `xray-demo` image visible in JFrog UI → Artifactory → `{nickname}-docker-xray-local`.

**Key concept**: `jf docker push` collects image layer metadata into Build Info as it pushes — this lets Xray associate vulnerabilities with a specific named build rather than just an anonymous image.

---

### xray-docker-T3 — Publish Docker Build Info (20 pts)

**Goal**: Publish build metadata to Artifactory so Xray has full context for scanning.

**Steps**:

```bash
jf rt build-collect-env ${NICKNAME}-xray-docker-build 1
jf rt build-publish ${NICKNAME}-xray-docker-build 1
```

Verify in Artifactory UI: **Artifactory → Builds → `{nickname}-xray-docker-build`**

---

### xray-docker-T4 — Create an Xray Security Policy and Watch for Docker (20 pts)

**Goal**: Create a Security policy to define CVE thresholds, then create a Watch to associate Docker repositories with the policy.

**Create Policy**:

1. JFrog UI → Xray → Policies → **New Policy**
2. Fill in:
   - **Name**: `{NICKNAME}-docker-policy` (must contain your nickname)
   - **Type**: Security
3. Add rule: Min Severity = High, optionally Block download
4. Save

**Create Watch**:

1. JFrog UI → Xray → Watches → **New Watch**
2. Fill in:
   - **Name**: `{NICKNAME}-docker-watch` (must contain your nickname)
3. Under Resources, add `{NICKNAME}-docker-xray-local` and `{NICKNAME}-docker-xray-remote`
4. Under Assigned Policies, add `{NICKNAME}-docker-policy`
5. Save

**Success indicator**: Both policy and watch visible in their lists with your nickname in the name.

---

### xray-docker-T5 — View Container Image CVE Scan Results (20 pts)

**Goal**: Explore the CVE report for your container image in the JFrog UI, including layer-level attribution.

**Steps**:

1. JFrog UI → Xray → Scans List → find `{NICKNAME}-xray-docker-build`
2. Explore:
   - **Violations**: CVEs that triggered your policy
   - **CVE Details**: CVSS score, affected package, fixed version
   - **Image Layer Analysis**: which layer introduced the vulnerability (base image vs application layer)

Optionally trigger an explicit scan:
```bash
jf rt build-scan ${NICKNAME}-xray-docker-build 1
```

**This task is manually verified — explore the UI then run the progress check to claim points.**

**Key concept**: Xray distinguishes whether a vulnerability comes from the base image (python:3.9-slim) or the application dependencies (requirements.txt). This attribution helps teams decide whether to rebuild with an updated base image or update a specific package.

---

## Troubleshooting

**Docker login fails**: Confirm the domain has no `https://` prefix; confirm the token has read/write permission.

**docker build fails**: Confirm you are inside `modules/xray-docker/sample-project`; confirm the Docker daemon is running.

**`jf docker push` returns 404**: Confirm `{nickname}-docker-xray-local` exists; verify the image tag path matches the repository key.

**Xray scan results empty**: Wait 1-3 minutes for Xray indexing; confirm `xrayIndex: true` was set when repos were created (`create-repo.sh` does this automatically).

**Xray menu not visible**: Confirm the JFrog instance has an active Xray license; ask the instructor to verify the environment.
