---
applyTo: "modules/jas-maven/**"
---

# jas-maven Module — AI Assistant Guide

You are guiding a participant through the **jas-maven** module of the JFrog Workshop. This module focuses on JFrog Advanced Security (JAS) with Maven: create Maven repositories, build and publish a project containing the Log4Shell vulnerability, run CVE scanning, SAST static analysis, and secrets detection, then view contextual reachability analysis in the JFrog UI.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Experience the full JFrog Advanced Security scanning suite with a Maven project:
- **CVE scanning**: detect high-severity vulnerabilities including Log4Shell (CVE-2021-44228)
- **SAST**: static code analysis for code-level security issues
- **Secrets detection**: find hardcoded API key in `App.java`
- **Contextual Analysis**: using JAR build artifacts to determine which CVEs are actually reachable in code

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| jas-maven-T1 | Create personal Maven repositories | 10 | `{nickname}-maven-jas-virtual` exists |
| jas-maven-T2 | Build Maven project through Artifactory and publish Build Info | 20 | `{nickname}-jas-maven-build/1` Build Info exists |
| jas-maven-T3 | Run jf audit --mvn to scan CVEs | 20 | Maven remote cache has content |
| jas-maven-T4 | Detect hardcoded secrets with JAS | 20 | Maven remote cache has content (audit ran) |
| jas-maven-T5 | View contextual analysis results in JFrog UI | 20 | Manual verification |
| **Total** | | **90** | |

**Prerequisites**: JFrog CLI installed, Java 11+, Maven (or use the Maven Wrapper `./mvnw` included in the sample project).

---

## Task Details

### jas-maven-T1 — Create Maven Repositories (10 pts)

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/jas-maven/create-repo.sh $NICKNAME
```

Expected output:
```
Creating Artifactory repositories for <nickname> (jas-maven)...
    ✅ Created: <nickname>-maven-jas-local
    ✅ Created: <nickname>-maven-jas-remote
    ✅ Created: <nickname>-maven-jas-virtual
✅ Repositories ready for <nickname>
```

---

### jas-maven-T2 — Build and Publish Build Info (20 pts)

**Goal**: Build the Maven project through Artifactory and publish Build Info for traceability and contextual analysis.

1. Configure JFrog CLI for Maven:
   ```bash
   cd modules/jas-maven/sample-project
   jf mvnc \
     --repo-resolve-releases=$NICKNAME-maven-jas-virtual \
     --repo-resolve-snapshots=$NICKNAME-maven-jas-virtual \
     --repo-deploy-releases=$NICKNAME-maven-jas-local \
     --repo-deploy-snapshots=$NICKNAME-maven-jas-local
   ```

2. Build:
   ```bash
   jf mvn install \
     --build-name=${NICKNAME}-jas-maven-build \
     --build-number=1
   ```

3. Publish Build Info:
   ```bash
   jf rt build-collect-env ${NICKNAME}-jas-maven-build 1
   jf rt build-publish ${NICKNAME}-jas-maven-build 1
   ```

**Success indicator**: Artifactory → Builds → `{nickname}-jas-maven-build` is visible in JFrog UI.

---

### jas-maven-T3 — Scan Maven CVEs (20 pts)

**Goal**: Run `jf audit` to detect known vulnerabilities in Maven dependencies, focusing on Log4Shell.

```bash
cd modules/jas-maven/sample-project
jf audit --mvn
```

**Expected findings**:
- **CVE-2021-44228** (Log4Shell): log4j-core 2.14.1 — Critical
- **CVE-2015-7501**: commons-collections 3.2.1 — High (deserialization)

**Success indicator**: CVE list displayed; `{nickname}-maven-jas-remote` cache has content.

**Key concept**: `jf audit --mvn` analyzes the dependency tree locally and matches against JFrog's vulnerability database (VulnDB) — no source code is uploaded to the server.

---

### jas-maven-T4 — Detect Hardcoded Secrets (20 pts)

**Goal**: Use JAS Secrets detection to find the hardcoded API key in `App.java`.

```bash
cd modules/jas-maven/sample-project
jf audit --mvn --secrets
```

**Expected finding**: Hardcoded API Key detected in `src/main/java/com/jfrog/workshop/App.java`.

**Key concept**: JAS Secrets detection uses ML models to identify credential patterns (API keys, passwords, OAuth tokens) across many formats with high precision.

---

### jas-maven-T5 — View Contextual Analysis (20 pts)

**Goal**: In JFrog UI, see which CVEs are marked as APPLICABLE (actually reachable) vs. just present.

1. Go to **Xray → Scans List → `{nickname}-jas-maven-build`**
2. Click on CVE-2021-44228 (Log4Shell)
3. Open the **Contextual Analysis** tab
4. Confirm: `App.java`'s `logger.error()` call marks Log4Shell as **APPLICABLE**

**Key concept**:
- **APPLICABLE**: there is a reachable code path that triggers the vulnerability
- **NOT APPLICABLE**: the vulnerable library is present but no reachable exploit path exists
- Maven JAR artifacts contain full bytecode — JAS can trace exact call chains. This is why Maven builds produce richer contextual analysis than script-based projects.

This is a manual verification task — complete the UI check and mark done.

---

## Troubleshooting

**`jf mvnc` fails**: Run `jf config show` to confirm Artifactory connection; verify repository names are correct.

**`jf mvn install` build fails**: Confirm Java ≥ 11 (`java -version`); ensure you are in the `modules/jas-maven/sample-project` directory.

**Audit shows "No vulnerabilities found"**: Confirm JFrog CLI is connected to an instance with Xray enabled; run `jf config show` to verify the URL.

**Contextual Analysis not showing**: Wait 2-3 minutes for Xray to finish scanning; confirm Build Info was published successfully (T2).
