---
applyTo: "modules/artifactory-maven/**"
---

# artifactory-maven Module — AI Assistant Guide

You are guiding a participant through the **artifactory-maven** module of the JFrog Workshop. This module focuses on Maven artifact proxying: create a personal Maven repository group in Artifactory, resolve Java dependencies through it, complete a build, and publish Build Info.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Use Artifactory as the central proxy for Maven dependencies: all dependency downloads are routed through Artifactory for caching, build artifacts are published to the personal local repository, and Build Info provides full Java artifact traceability.

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| artifactory-maven-T1 | Create personal Maven repositories in Artifactory | 10 | `{nickname}-maven-virtual` repository exists |
| artifactory-maven-T2 | Complete first Maven build through Artifactory | 20 | `{nickname}-maven-remote-cache` has cached dependencies |
| artifactory-maven-T3 | Publish Maven Build Info to Artifactory | 20 | `{nickname}-maven-build` Build Info exists |
| **Total** | | **50** | |

**Prerequisites**: Java JDK 11+ and Maven 3.6+ installed. No additional JFrog features required.

---

## Task Details

### artifactory-maven-T1 — Create Personal Maven Repositories (10 pts)

**Goal**: Create three Maven repositories (local / remote / virtual) forming a complete proxy chain.

**Steps**:

Confirm your profile is loaded:
```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
```

Run:
```bash
bash modules/artifactory-maven/create-repo.sh $NICKNAME
```

Expected output:
```
Creating Artifactory repositories for <nickname> (artifactory-maven)...
    ✅ Created: <nickname>-maven-local
    ✅ Created: <nickname>-maven-remote
    ✅ Created: <nickname>-maven-virtual
✅ Repositories ready for <nickname>
```

**Success indicator**: All three repositories visible in JFrog UI → Artifactory → Repositories.

---

### artifactory-maven-T2 — Complete First Maven Build Through Artifactory (20 pts)

**Goal**: Configure Maven to resolve dependencies through Artifactory, complete the build, and cache dependencies.

**Steps**:

1. Configure JFrog CLI (skip if already done):
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

2. Navigate to the sample project:
   ```bash
   cd modules/artifactory-maven/sample-project
   ```

3. Configure Maven to resolve through Artifactory:
   ```bash
   jf mvnc \
     --repo-resolve-releases=${NICKNAME}-maven-virtual \
     --repo-resolve-snapshots=${NICKNAME}-maven-virtual \
     --repo-deploy-releases=${NICKNAME}-maven-local \
     --repo-deploy-snapshots=${NICKNAME}-maven-local
   ```

4. Run the build:
   ```bash
   jf mvn clean install \
     --build-name=${NICKNAME}-maven-build \
     --build-number=1
   ```

**Success indicator**: Build ends with `BUILD SUCCESS` and `{nickname}-maven-remote-cache` has cached dependencies.

**Key concept**: Proxying Maven Central through Artifactory caches all downloaded jars — builds remain reliable when upstream is unavailable, and you gain full dependency visibility.

---

### artifactory-maven-T3 — Publish Maven Build Info (20 pts)

**Goal**: Publish build metadata (dependency list, module info, environment variables) to Artifactory for full traceability.

**Steps**:

```bash
jf rt build-collect-env ${NICKNAME}-maven-build 1
jf rt build-publish ${NICKNAME}-maven-build 1
```

Verify in Artifactory UI:
**Artifactory → Builds → `{nickname}-maven-build`**

**Success indicator**: Build record appears in the Builds list with dependency tree and module details visible.

---

## Troubleshooting

**`jf mvn` command not found**: Confirm JFrog CLI version ≥ 2.x with `jf --version`; confirm `jf config use workshop` has been run.

**Build returns 401 / 403**: Check `jf config show` for correct URL and token; confirm `{nickname}-maven-virtual` exists.

**Dependency download fails (connection refused)**: Check that `{nickname}-maven-remote` is configured to proxy Maven Central (`https://repo1.maven.org/maven2`).

**Build Info publish fails**: Confirm `jf mvn` was run with `--build-name` and `--build-number` — without these flags there is no build info to publish.
