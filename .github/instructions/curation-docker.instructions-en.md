---
applyTo: "modules/curation-docker/**"
---

# curation-docker Module — AI Assistant Guide

You are guiding a participant through the **curation-docker** module of the JFrog Workshop. This module focuses on Docker image supply chain protection: route image pulls through Artifactory Curation, create a Curation policy to block non-compliant base images, and verify blocked pulls in the Audit log.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Use JFrog Curation to protect the Docker supply chain at pull time: all `docker pull` requests are routed through Artifactory virtual repositories, and Curation policies intercept non-compliant images (high CVEs, malicious packages) before they enter the internal network.

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| curation-docker-T1 | Create personal Docker repositories in Artifactory | 10 | `{nickname}-docker-curated-virtual` repo exists |
| curation-docker-T2 | Pull a Docker image through Artifactory Curation | 20 | `{nickname}-docker-curated-remote` cache has content |
| curation-docker-T3 | Create a Docker Curation Policy | 20 | Policy name contains nickname |
| curation-docker-T4 | Trigger Curation to block a non-compliant image | 20 | Curation Audit has a Docker blocked record for your repos |
| curation-docker-T5 | View blocked image in Curation Audit | 20 | Manual verification (UI exploration) |
| **Total** | | **90** | |

**Prerequisites**: JFrog instance has Curation enabled; Docker is installed; the JFrog instance domain is accessible for Docker pulls.

---

## Task Details

### curation-docker-T1 — Create Personal Docker Repositories (10 pts)

**Goal**: Create three Docker repositories (local / remote / virtual) with Curation enabled on the remote.

**Steps**:

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/curation-docker/create-repo.sh $NICKNAME
```

Expected output:
```
Creating Artifactory repositories for <nickname> (curation-docker)...
    ✅ Created: <nickname>-docker-curated-local
    ✅ Created: <nickname>-docker-curated-remote
    ✅ Created: <nickname>-docker-curated-virtual
✅ Repositories ready for <nickname>
```

**Success indicator**: All three repos visible in JFrog UI → Artifactory → Repositories; the remote repo shows as Curated.

---

### curation-docker-T2 — Pull a Docker Image Through Artifactory Curation (20 pts)

**Goal**: Route a Docker pull through Artifactory to verify images flow through the Curation pipeline.

**Steps**:

1. Configure JFrog CLI (skip if already done):
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

2. Log in to the Artifactory Docker virtual registry:
   ```bash
   docker login ${JFROG_URL#https://} -u $NICKNAME -p $JFROG_TOKEN
   ```

3. Pull an image through Artifactory:
   ```bash
   DOCKER_REGISTRY="${JFROG_URL#https://}/docker"
   docker pull ${DOCKER_REGISTRY}/${NICKNAME}-docker-curated-virtual/python:3.9-slim
   ```

**Success indicator**: Pull succeeds; `{nickname}-docker-curated-remote` cache has content.

**Key concept**: Pointing Docker at an Artifactory virtual repository routes all pulls through Curation — developers don't need to change their workflow, security policies enforce silently in the background.

---

### curation-docker-T3 — Create a Docker Curation Policy (20 pts)

**Goal**: Create a Curation policy targeting your Docker remote repository to block high-severity CVEs.

**Steps**:

1. JFrog UI → Curation → Policies → **New Policy**
2. Fill in:
   - **Name**: `{NICKNAME}-docker-curation` (must contain your nickname)
   - **Repository**: select `{NICKNAME}-docker-curated-remote`
3. Add a rule (choose one or more):
   - CVE severity: Block if High/Critical CVEs detected
   - Malicious package: Block known malicious packages
4. Save the policy

**Success indicator**: Policy visible in Curation → Policies list with your nickname in the name.

**Key concept**: Curation acts *before* an image enters your network — unlike Xray which scans what's already stored. Curation is the first line of defense; Xray is the continuous audit layer.

---

### curation-docker-T4 — Trigger Curation to Block a Non-Compliant Image (20 pts)

**Goal**: Attempt to pull an image that your Curation policy will block, confirming the policy works.

**Steps**:

Try pulling an older Python image with known vulnerabilities:
```bash
DOCKER_REGISTRY="${JFROG_URL#https://}/docker"
docker pull ${DOCKER_REGISTRY}/${NICKNAME}-docker-curated-virtual/python:3.8
```

If the policy is configured correctly, the pull will be rejected with a message like:
```
Error response from daemon: pull access denied ... blocked by Curation policy
```

**Success indicator**: Curation Audit shows a blocked entry from `{nickname}-docker-curated-remote`.

**If the pull is not blocked**:
- Confirm the policy from T3 is applied to `{nickname}-docker-curated-remote`
- Check the rule's Min CVE Severity is set to High or Critical
- Try an older tag like `python:2.7` or `python:3.6` which have more known CVEs

---

### curation-docker-T5 — View Blocked Image in Curation Audit (20 pts)

**Goal**: Explore the Curation Audit log to understand the block record and violation details.

**Steps**:

1. JFrog UI → Curation → Audit
2. Find the blocked pull record for your repository
3. Explore:
   - **Blocked image**: name and tag
   - **Block reason**: which policy rule triggered (CVE severity, malicious package, etc.)
   - **CVE details**: if blocked for CVEs, view the specific vulnerability information

**This task is manually verified — explore the UI then run the progress check to claim points.**

**Key concept**: The Curation Audit log is your compliance evidence. Every block is recorded with timestamp, image identity, triggering rule, and CVE details — proof that your supply chain gate is working.

---

## Troubleshooting

**Docker login fails**: Confirm domain has no `https://` prefix; confirm the token is valid.

**Pull returns "repository does not exist"**: Confirm the virtual repo name is spelled correctly; confirm `create-repo.sh` completed successfully.

**Policy created but pull is not blocked**: Confirm the policy is applied to the correct remote repo; wait 1-2 minutes for the policy to take effect; try an older image tag (`python:2.7`).

**Curation menu not visible**: Confirm the JFrog instance has Curation licensed and enabled; ask the instructor to verify the environment.
