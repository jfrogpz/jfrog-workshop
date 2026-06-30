---
applyTo: "modules/ci-jenkins/**"
---

# ci-jenkins Module — AI Assistant Guide

You are guiding a participant through the **ci-jenkins** module of the JFrog Workshop. This module focuses on integrating Jenkins CI/CD pipelines with JFrog Artifactory: building artifacts, publishing Build Info, and triggering Xray security scans.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Complete an end-to-end artifact management flow through a Jenkins pipeline: build an npm package from source, publish artifacts to Artifactory, upload Build Info for full traceability, and scan with Xray for supply chain security.

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| ci-jenkins-T1 | Connect Jenkins to JFrog Artifactory | 10 | At least one build record exists in Artifactory |
| ci-jenkins-T2 | Create Artifactory repositories for Jenkins builds | 10 | `{nickname}-jenkins-npm-virtual` repository exists |
| ci-jenkins-T3 | Run pipeline and publish artifacts to Artifactory | 20 | Artifacts present in `{nickname}-jenkins-npm-local` |
| ci-jenkins-T4 | Publish Build Info from Jenkins | 20 | `{nickname}-jenkins-build` Build Info exists in Artifactory |
| ci-jenkins-T5 | Trigger Xray scan on the Jenkins build | 20 | Xray scan status is completed |
| **Total** | | **80** | |

**Prerequisites**:
- A running Jenkins instance (accessible from the internet)
- JFrog CLI installed on the Jenkins agent (or declared via `tool`)
- Artifactory instance with Xray enabled and a Watch configured

---

## Task Details

### ci-jenkins-T1 — Connect Jenkins to JFrog Artifactory (10 pts)

**Goal**: Install the JFrog plugin in Jenkins and configure Artifactory server credentials.

#### Step 1: Install the JFrog Jenkins Plugin

1. Open Jenkins UI → **Manage Jenkins** → **Plugins** → **Available plugins**
2. Search for `JFrog`, find the official **JFrog** plugin
3. Check it and click **Install**
4. Restart Jenkins after installation

> 📖 [Plugin installation docs](https://jfrog.com/help/r/jfrog-integrations-documentation/jenkins-artifactory-plug-in)

#### Step 2: Configure the Artifactory Server

1. Go to **Manage Jenkins** → **System** → find the **JFrog** section
2. Click **Add JFrog Platform Instance** and fill in:
   - **Instance ID**: `workshop`
   - **JFrog Platform URL**: `$JFROG_URL` (e.g. `https://xxx.jfrog.io`)
3. Under **Default Deployer Credentials**, click **Add** → **Jenkins**:
   - Kind: **Secret text**
   - Secret: your `$JFROG_TOKEN`
   - ID: `jfrog-token`
4. Click **Test Connection** — confirm it shows **Found JFrog Artifactory ...**
5. Click **Save**

**Success indicator**: Test Connection shows a green success message with the Artifactory version.

---

### ci-jenkins-T2 — Create Artifactory Repositories (10 pts)

**Goal**: Create a personal npm repository group for the Jenkins pipeline.

Run in the Codespace terminal:

```bash
source ~/.workshop-profile
bash modules/ci-jenkins/create-repo.sh $NICKNAME
```

This creates: `{nickname}-jenkins-npm-local`, `{nickname}-jenkins-npm-remote`, `{nickname}-jenkins-npm-virtual`

**Success indicator**: All three repositories are visible in JFrog UI → Artifactory → Repositories.

---

### ci-jenkins-T3 — Run Pipeline and Publish Artifacts (20 pts)

**Goal**: Create a Jenkins pipeline job using the provided Jenkinsfile and publish npm artifacts to Artifactory.

#### Step 1: Add Jenkins Credentials

Go to **Manage Jenkins** → **Credentials** → **Global** → **Add Credentials** and create three **Secret text** entries:

| ID | Value | Description |
|----|-------|-------------|
| `jfrog-url` | value of `$JFROG_URL` | JFrog instance URL |
| `jfrog-token` | value of `$JFROG_TOKEN` | Access Token |
| `jfrog-nickname` | your nickname | Personal repo prefix |

#### Step 2: Create the Pipeline Job

1. Jenkins home → **New Item**
2. Name: `<NICKNAME>-jfrog-workshop`
3. Type: **Pipeline** → **OK**
4. Under **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: this workshop repo URL
   - Script Path: `modules/ci-jenkins/sample-project/Jenkinsfile`
5. Click **Save**

#### Step 3: Trigger a Build

Click **Build Now** and check the Console Output for:
- `jf config add` succeeds
- `jf rt ping` returns `OK`
- `jf npm install` downloads dependencies
- Build ends with `Finished: SUCCESS`

**Success indicator**: npm packages appear in `<NICKNAME>-jenkins-npm-local` in the JFrog UI.

---

### ci-jenkins-T4 — Publish Build Info from Jenkins (20 pts)

**Goal**: Confirm that Build Info was published to Artifactory, enabling full artifact traceability.

The Jenkinsfile's **Publish Build Info** stage handles this automatically:

```groovy
jf rt build-collect-env "${BUILD_NAME}" "${BUILD_NUMBER}"
jf rt build-publish "${BUILD_NAME}" "${BUILD_NUMBER}"
```

#### Verify in Artifactory UI

1. JFrog UI → **Artifactory** → **Builds**
2. Find `<NICKNAME>-jenkins-build`
3. Click in to see:
   - **Modules**: npm dependency list for this build
   - **Environment**: Jenkins environment variables
   - **Published**: timestamp matching the Jenkins build

**Success indicator**: `<NICKNAME>-jenkins-build` appears in Artifactory Builds with dependency details.

> 📖 [Build Info docs](https://jfrog.com/help/r/jfrog-cli/publishing-build-info)

---

### ci-jenkins-T5 — Trigger Xray Scan on the Jenkins Build (20 pts)

**Goal**: Scan the build's dependencies with Xray to detect CVEs and license risks.

The Jenkinsfile's **Xray Scan** stage triggers this automatically:

```groovy
jf rt build-scan --fail=false "${BUILD_NAME}" "${BUILD_NUMBER}"
```

`--fail=false` means the pipeline won't fail even if vulnerabilities are found (suitable for workshop learning).

#### View Scan Results in Artifactory UI

1. JFrog UI → **Artifactory** → **Builds** → `<NICKNAME>-jenkins-build`
2. Click the build number
3. Switch to the **Xray Data** tab
4. Review:
   - **Security Issues**: CVE list with severity (Critical / High / Medium)
   - **License Issues**: dependency license compliance

**Success indicator**: Xray Data tab shows scan status as completed with CVE details visible.

---

## Troubleshooting

**Test Connection fails / Connection refused**
- Check the JFrog Platform URL has no trailing `/`
- Verify the token is valid: `curl -H "Authorization: Bearer $JFROG_TOKEN" $JFROG_URL/artifactory/api/system/ping`

**`jf rt ping` returns 401 in Jenkins**
- Confirm the Credentials ID exactly matches `credentials('jfrog-token')` in the Jenkinsfile
- Make sure the credentials are in Global scope, not a Folder scope

**`jf npm install` returns E404 / package not found**
- Confirm T2 is complete and `<NICKNAME>-jenkins-npm-virtual` exists
- Check the Console Output to see what value `VIRTUAL_REPO` resolved to

**Build Info not found in Artifactory**
- Check the Console Output for errors in the `jf rt build-publish` step
- Confirm the build name includes your NICKNAME

**Xray Data tab empty**
- Xray scanning is asynchronous — wait 1-2 minutes and refresh
- Confirm Xray is enabled and a Watch covers `{nickname}-jenkins-npm-local` (organizer pre-configuration)
