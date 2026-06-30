---
applyTo: "modules/ci-github-actions/**"
---

# ci-github-actions Module — AI Assistant Guide

You are guiding a participant through the **ci-github-actions** module of the JFrog Workshop. This module focuses on integrating JFrog CLI into GitHub Actions: create Artifactory repositories, configure the `setup-jfrog-cli` Action, run an npm build through Artifactory in CI, publish artifacts and Build Info, and trigger an Xray scan.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Integrate JFrog Platform into a GitHub Actions CI pipeline: authenticate with the official `setup-jfrog-cli` Action, resolve npm packages through Artifactory, upload artifacts, publish Build Info for full traceability, and trigger Xray scanning — all within a single GitHub Actions workflow.

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| ci-github-actions-T1 | Create Artifactory repositories for GitHub Actions builds | 10 | `{nickname}-npm-gha-virtual` repo exists |
| ci-github-actions-T2 | Configure JFrog CLI in GitHub Actions workflow | 20 | `{nickname}-npm-gha-remote` cache has content (workflow ran) |
| ci-github-actions-T3 | Run workflow and publish artifacts to Artifactory | 20 | `{nickname}-npm-gha-local` has artifacts |
| ci-github-actions-T4 | Publish Build Info from GitHub Actions to Artifactory | 20 | `{nickname}-gha-build/1` Build Info exists |
| ci-github-actions-T5 | Trigger Xray scan on the GitHub Actions build | 20 | Xray scan results exist for the build |
| **Total** | | **90** | |

**Prerequisites**: A GitHub account with a repository where Actions can be enabled; JFrog URL and Access Token ready to configure as GitHub Secrets.

---

## Task Details

### ci-github-actions-T1 — Create Artifactory Repositories (10 pts)

**Goal**: Create three Xray-indexed npm repositories for the GitHub Actions pipeline.

**Steps**:

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/ci-github-actions/create-repo.sh $NICKNAME
```

Expected output:
```
Creating Artifactory repositories for <nickname> (ci-github-actions)...
    ✅ Created: <nickname>-npm-gha-local
    ✅ Created: <nickname>-npm-gha-remote
    ✅ Created: <nickname>-npm-gha-virtual
✅ Repositories ready for <nickname>
```

---

### ci-github-actions-T2 — Configure JFrog CLI in GitHub Actions (20 pts)

**Goal**: Add JFrog authentication to a GitHub repository so the Actions workflow can use JFrog CLI.

**Steps**:

1. **Fork or create a GitHub repository** and copy the files from `modules/ci-github-actions/sample-project/`.

2. **Configure GitHub Secrets** (Settings → Secrets and variables → Actions):
   - `JFROG_URL` = your JFrog instance URL
   - `JFROG_ACCESS_TOKEN` = your Access Token
   - `NICKNAME` = your workshop nickname

3. **Verify the workflow file** `.github/workflows/jfrog-build.yml` includes:
   ```yaml
   - name: Setup JFrog CLI
     uses: jfrog/setup-jfrog-cli@v4
     env:
       JF_URL: ${{ secrets.JFROG_URL }}
       JF_ACCESS_TOKEN: ${{ secrets.JFROG_ACCESS_TOKEN }}
   ```

4. **Trigger the workflow**: push a commit or manually trigger (Actions → Run workflow).

**Success indicator**: Workflow runs successfully; `{nickname}-npm-gha-remote` cache has content.

**Key concept**: `jfrog/setup-jfrog-cli` is the official GitHub Action that installs JFrog CLI and configures authentication in one step — replacing manual installation and `jf config add` commands, which is not suitable for ephemeral CI runners.

---

### ci-github-actions-T3 — Run Workflow and Publish Artifacts (20 pts)

**Goal**: Confirm the GitHub Actions workflow completed an npm build and uploaded artifacts to Artifactory.

**Verify in JFrog UI**: Artifactory → Repositories → `{nickname}-npm-gha-local` has content.

Key workflow steps:
```yaml
- name: Configure npm to use Artifactory
  run: |
    jf npmc \
      --repo-resolve=${{ secrets.NICKNAME }}-npm-gha-virtual \
      --repo-deploy=${{ secrets.NICKNAME }}-npm-gha-local

- name: Install dependencies
  run: |
    jf npm install \
      --build-name=${{ env.BUILD_NAME }} \
      --build-number=${{ env.BUILD_NUMBER }}
```

**Success indicator**: `{nickname}-npm-gha-local` repository has artifacts.

---

### ci-github-actions-T4 — Publish Build Info (20 pts)

**Goal**: Confirm the workflow published Build Info to Artifactory for full CI traceability.

Key workflow steps:
```yaml
- name: Collect environment variables
  run: jf rt build-collect-env ${{ env.BUILD_NAME }} ${{ env.BUILD_NUMBER }}

- name: Publish Build Info
  run: jf rt build-publish ${{ env.BUILD_NAME }} ${{ env.BUILD_NUMBER }}
```

**Verify in JFrog UI**: Artifactory → Builds → `{nickname}-gha-build`

**Success indicator**: Build Info record exists with dependency list and environment info.

**Key concept**: Publishing Build Info from CI links every GitHub Actions run to its artifacts in Artifactory — creating a traceable chain from git commit → CI run → artifact → Xray scan.

---

### ci-github-actions-T5 — Trigger Xray Scan (20 pts)

**Goal**: Confirm the workflow triggered an Xray scan and results are visible in the JFrog UI.

Key workflow step:
```yaml
- name: Trigger Xray Scan
  run: |
    jf rt build-scan ${{ env.BUILD_NAME }} ${{ env.BUILD_NUMBER }} || true
```

**Verify in JFrog UI**: Xray → Scans List → `{nickname}-gha-build`

**Success indicator**: Xray scan results exist for the build.

**Key concept**: `|| true` runs Xray in non-blocking mode — scan results are recorded but vulnerabilities don't fail the CI job. Remove `|| true` in production to make the pipeline fail on policy violations.

---

## Troubleshooting

**Workflow reports "JFROG_URL not set"**: Confirm GitHub Secrets are configured correctly (case-sensitive); verify the workflow references the exact secret names.

**`jf npmc` fails**: Confirm `setup-jfrog-cli` Action ran before this step; confirm repository names are correct.

**Build Info publish fails**: Confirm `jf npm install` was run with `--build-name` and `--build-number`; confirm `build-collect-env` runs before `build-publish`.

**Xray scan has no results**: Wait 2-3 minutes; confirm repositories have Xray indexing enabled (`create-repo.sh` sets `xrayIndex: true`).
