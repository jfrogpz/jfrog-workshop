---
applyTo: "modules/artifactory-docker/**"
---

# artifactory-docker Module — AI Assistant Guide

You are guiding a participant through the **artifactory-docker** module of the JFrog Workshop. This module focuses on Docker artifact proxying: create a personal Docker repository group in Artifactory, pull images through it, build and push a custom image, and publish Build Info.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Use Artifactory as the central proxy and registry for Docker images: all pull traffic is routed through Artifactory for caching, all custom images are pushed to a personal local repository, and Build Info provides full artifact traceability.

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| artifactory-docker-T1 | Create personal Docker repositories in Artifactory | 10 | `{nickname}-docker-virtual` repository exists |
| artifactory-docker-T2 | Pull a Docker image through Artifactory | 20 | `{nickname}-docker-remote-cache` has cached content |
| artifactory-docker-T3 | Build and push a Docker image to Artifactory | 20 | Image present in `{nickname}-docker-local` |
| artifactory-docker-T4 | Publish Docker Build Info to Artifactory | 20 | `{nickname}-docker-build` Build Info exists |
| **Total** | | **70** | |

**Prerequisites**: Docker Engine or Docker Desktop installed. JFrog Artifactory instance with Docker package type support.

---

## Task Details

### artifactory-docker-T1 — Create Personal Docker Repositories (10 pts)

**Goal**: Create three repositories (local / remote / virtual) forming a complete Docker proxy chain.

**Steps**:

Confirm your profile is loaded:
```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
```

Run:
```bash
bash modules/artifactory-docker/create-repo.sh $NICKNAME
```

Expected output:
```
Creating Artifactory repositories for <nickname> (artifactory-docker)...
    ✅ Created: <nickname>-docker-local
    ✅ Created: <nickname>-docker-remote
    ✅ Created: <nickname>-docker-virtual
✅ Repositories ready for <nickname>
```

**Success indicator**: All three repositories visible in JFrog UI → Artifactory → Repositories.

---

### artifactory-docker-T2 — Pull a Docker Image Through Artifactory (20 pts)

**Goal**: Log Docker into Artifactory and pull a public image through the virtual repository.

**Steps**:

1. Get your Artifactory domain (strip `https://`):
   ```bash
   JFROG_DOMAIN=$(echo $JFROG_URL | sed 's|https://||')
   echo $JFROG_DOMAIN
   ```

2. Log Docker into Artifactory:
   ```bash
   docker login ${JFROG_DOMAIN} -u $JFROG_USER -p $JFROG_TOKEN
   ```

3. Pull an image through the virtual repository:
   ```bash
   docker pull ${JFROG_DOMAIN}/${NICKNAME}-docker-virtual/alpine:3.18
   ```

**Success indicator**: Pull succeeds and `{nickname}-docker-remote-cache` has cached content.

**Key concept**: Once pulled through Artifactory, the image is cached — subsequent pulls hit the cache even if Docker Hub is unavailable.

---

### artifactory-docker-T3 — Build and Push a Docker Image (20 pts)

**Goal**: Build a custom image from the sample Dockerfile, push it to the personal local repository, and record Build Info.

**Steps**:

1. Navigate to the sample project:
   ```bash
   cd modules/artifactory-docker/sample-project
   ```

2. Configure JFrog CLI (skip if already configured):
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

3. Build the image:
   ```bash
   jf docker build \
     -t ${JFROG_DOMAIN}/${NICKNAME}-docker-local/workshop-app:1.0 \
     --build-name=${NICKNAME}-docker-build \
     --build-number=1 \
     .
   ```

4. Push the image:
   ```bash
   jf docker push \
     ${JFROG_DOMAIN}/${NICKNAME}-docker-local/workshop-app:1.0 \
     --build-name=${NICKNAME}-docker-build \
     --build-number=1
   ```

**Success indicator**: `workshop-app` image appears in `{nickname}-docker-local`.

---

### artifactory-docker-T4 — Publish Docker Build Info (20 pts)

**Goal**: Publish build metadata to Artifactory to record the full image layer dependency chain.

**Steps**:

```bash
jf rt build-collect-env ${NICKNAME}-docker-build 1
jf rt build-publish ${NICKNAME}-docker-build 1
```

Verify in Artifactory UI:
**Artifactory → Builds → `{nickname}-docker-build`**

**Success indicator**: Build record appears in the Builds list with image layer and environment details.

---

## Troubleshooting

**docker login returns 401**: Confirm `JFROG_TOKEN` is valid and the user has access to the repository.

**docker pull returns not found**: Confirm the virtual repository name is correct and the remote repository is configured to proxy Docker Hub.

**jf docker build unknown flag**: Confirm JFrog CLI version ≥ 2.x — run `jf --version` to check.

**Build Info not found**: Confirm `jf docker push` was run with `--build-name` and `--build-number` flags.
