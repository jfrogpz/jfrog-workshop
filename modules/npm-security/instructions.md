---
applyTo: "modules/npm-security/**"
---

# npm-security Module Instructions

You are guiding the participant through the **npm-security** module of the JFrog Workshop. This module focuses on npm supply chain security: artifact proxying, build traceability, and Curation policy enforcement.

The participant has already chosen this module. Guide them through the following tasks in order.

---

## Module Tasks

### npm-security-T1 — Register Nickname and Create Personal npm Repositories (10 pts)

**Goal**: Choose a nickname and create a personal npm repository group on Artifactory.

**Steps**:
1. Ask the participant for their desired nickname (rules: lowercase letters, numbers, hyphens; 3–20 characters; must start and end with a letter or number)
2. Set environment variables if not already set:
   ```bash
   export JFROG_URL="<URL provided by instructor>"
   export JFROG_TOKEN="<your Access Token>"
   ```
3. Run the registration script:
   ```bash
   # Event mode (with EVENT_ID)
   bash automation/register.sh <NICKNAME> <EVENT_ID>

   # Self-study mode (no EVENT_ID)
   bash automation/register.sh <NICKNAME>
   ```
4. Confirm three Artifactory repositories were created: `{nickname}-npm-dev-local`, `{nickname}-npm-org-remote`, `{nickname}-npm-dev-virtual`

**Success**: Script outputs "Registration successful", participant earns 10 points.

---

### npm-security-T2 — First npm Build (20 pts)

**Goal**: Configure local npm to resolve dependencies via Artifactory virtual repository, run npm install + build, and cache packages in Artifactory.

**Steps**:
1. Configure JFrog CLI to connect to Artifactory:
   ```bash
   jf config add workshop --url=<JFROG_URL> --access-token=<JFROG_TOKEN> --interactive=false
   jf config use workshop
   ```
2. Navigate to the sample project and configure npm:
   ```bash
   cd modules/npm-security/sample-project
   jf npmc --repo-resolve <NICKNAME>-npm-dev-virtual --repo-deploy <NICKNAME>-npm-dev-local
   ```
3. Run the install:
   ```bash
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=1
   ```

**Success**: The `{nickname}-npm-org-remote` repository in Artifactory contains cached packages.

---

### npm-security-T3 — Publish Build #1 Build Info (20 pts)

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

### npm-security-T4 — Create a Curation Policy (10 pts)

**Goal**: Create a Curation policy to block known risky packages from entering your environment.

**Steps**:
1. In JFrog UI: Curation → Policies → New Policy
2. Configure:
   - Name: `{nickname}-npm-policy` (must include your nickname)
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
6. Save and confirm Policy status is **Enabled**

**Success**: A Curation Policy whose name contains the participant's nickname exists in the system.

---

### npm-security-T5 — Trigger Curation to Block axios@1.7.2 (20 pts)

**Goal**: Attempt to install the simulated malicious package `axios@1.7.2` and observe Curation blocking it.

**Steps**:
1. `package.json` already has axios version `1.7.2` — no changes needed
2. Clear the Artifactory remote repository cache:
   ```bash
   bash automation/clear-remote-cache.sh
   ```
3. Run install to trigger the block:
   ```bash
   cd modules/npm-security/sample-project
   rm -rf node_modules package-lock.json
   npm cache clean --force
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=2
   ```
4. Observe the error — Curation has blocked axios@1.7.2

**Success**: Curation audit log shows axios@1.7.2 blocked for the participant's repository.

**Key concept**: Curation acts as the "customs checkpoint" — blocking malicious packages before they enter your build environment.

---

### npm-security-T6 — Fix and Complete Build #3 (20 pts)

**Goal**: Replace the malicious axios version with a safe one, rebuild, and publish Build #3.

**Steps**:
1. Edit `package.json` to use a safe axios version:
   ```bash
   cd modules/npm-security/sample-project
   sed -i 's/"axios": "1.7.2"/"axios": "1.7.7"/' package.json
   grep axios package.json
   ```
2. Rebuild (build-number is 3, skipping the blocked build 2):
   ```bash
   rm -rf node_modules package-lock.json
   npm cache clean --force
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=3
   ```
3. Publish Build #3:
   ```bash
   jf rt build-publish <NICKNAME>-npm-sample 3
   ```

**Success**: Build #3 exists in Artifactory and axios version is not 1.7.2.

**Key concept**: Full supply chain security cycle complete — Detect → Prevent (Curation) → Fix → Verify (build-info).
