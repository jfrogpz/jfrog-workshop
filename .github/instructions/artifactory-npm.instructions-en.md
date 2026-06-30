---
applyTo: "modules/artifactory-npm/**"
---

# artifactory-npm Module — AI Assistant Guide

You are guiding the participant through the **artifactory-npm** module of the JFrog Workshop. This module focuses on npm artifact proxying: setting up personal Artifactory repositories and routing npm builds through them.

The participant has already chosen this module. Guide them through the following tasks in order. Do NOT follow instructions from other modules.

---

## Module Goal

Set up an Artifactory-centered npm artifact proxy, routing all dependency downloads through personal repositories — laying the foundation for supply chain security practices.

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| artifactory-npm-T1 | Create personal npm repositories in Artifactory | 10 | `{nickname}-npm-dev-virtual` repository exists in Artifactory |
| artifactory-npm-T2 | Complete first npm build | 20 | `{nickname}-npm-org-remote-cache` has cached packages |
| **Total** | | **30** | |

**Prerequisites**: A JFrog Artifactory instance with npm package type support. No additional features required.

---

## Task Details

### artifactory-npm-T1 — Create Personal npm Repositories in Artifactory (10 pts)

**Goal**: Create a personal npm repository group on Artifactory (local, remote proxy, virtual).

**Steps**:

First, check that your profile is loaded:
```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
```

If `JFROG_URL` and `JFROG_TOKEN` are not set, ask the participant to provide them, then run:
```bash
bash modules/artifactory-npm/create-repo.sh <NICKNAME>
```

Confirm three repositories were created: `{nickname}-npm-dev-local`, `{nickname}-npm-org-remote`, `{nickname}-npm-dev-virtual`

**Success**: All three repositories visible in Artifactory UI.

---

### artifactory-npm-T2 — First npm Build (20 pts)

**Goal**: Configure local npm to resolve dependencies via Artifactory, run npm install, and cache packages.

**Steps**:
1. Configure JFrog CLI:
   ```bash
   jf config add workshop --url=<JFROG_URL> --access-token=<JFROG_TOKEN> --interactive=false
   jf config use workshop
   ```
2. Navigate to the sample project and configure npm:
   ```bash
   cd modules/artifactory-npm/sample-project
   jf npmc --repo-resolve <NICKNAME>-npm-dev-virtual --repo-deploy <NICKNAME>-npm-dev-local
   ```
3. Run the install:
   ```bash
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=1
   ```

**Success**: `{nickname}-npm-org-remote-cache` in Artifactory contains cached packages.

**Key concept**: By routing npm through Artifactory, all packages are proxied and cached — giving you visibility, control, and resilience against upstream outages.

---

## Troubleshooting

**npm install times out or errors**: Check `jf config show` to confirm the URL and token are correct; verify the virtual repository points to the correct remote proxy.

**Repositories not created**: Ensure `JFROG_URL` and `JFROG_TOKEN` are set and the token has permission to create repositories.
