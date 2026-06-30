---
applyTo: "modules/curation-ai/**"
---

# curation-ai Module — AI Assistant Guide

You are guiding a participant through the **curation-ai** module of the JFrog Workshop. This module focuses on AI/ML package supply chain governance: route pip installs through Artifactory Curation to control AI dependencies (numpy, torch, transformers, etc.), block vulnerable package versions, and audit the governance trail.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Use JFrog Curation to govern AI/ML package supply chains: route all `pip install` requests through Artifactory, create a PyPI Curation policy to block high-CVE AI package versions, trigger a block, and verify the audit trail.

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| curation-ai-T1 | Create a Curated PyPI repository for AI packages | 10 | `{nickname}-pypi-ai-virtual` repo exists |
| curation-ai-T2 | Install AI packages through Artifactory Curation | 20 | `{nickname}-pypi-ai-remote` cache has content |
| curation-ai-T3 | Create a Curation Policy for AI packages | 20 | Policy name contains nickname |
| curation-ai-T4 | Block a vulnerable AI package version | 20 | Curation Audit has a PyPI blocked record for your repos |
| curation-ai-T5 | Review AI package governance in Curation Audit | 20 | Manual verification (UI exploration) |
| **Total** | | **90** | |

**Prerequisites**: JFrog instance has Curation enabled; Python 3 and pip installed; pip can reach the JFrog instance.

---

## Task Details

### curation-ai-T1 — Create a Curated PyPI Repository (10 pts)

**Goal**: Create three PyPI repositories (local / remote / virtual) with Curation enabled on the remote.

**Steps**:

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/curation-ai/create-repo.sh $NICKNAME
```

Expected output:
```
Creating Artifactory repositories for <nickname> (curation-ai)...
    ✅ Created: <nickname>-pypi-ai-local
    ✅ Created: <nickname>-pypi-ai-remote
    ✅ Created: <nickname>-pypi-ai-virtual
✅ Repositories ready for <nickname>
```

---

### curation-ai-T2 — Install AI Packages Through Artifactory Curation (20 pts)

**Goal**: Route pip installs through Artifactory to verify AI packages flow through the Curation pipeline.

**Steps**:

1. Configure JFrog CLI (skip if already done):
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

2. Navigate to the sample project and install:
   ```bash
   cd modules/curation-ai/sample-project
   PYPI_INDEX="${JFROG_URL}/artifactory/api/pypi/${NICKNAME}-pypi-ai-virtual/simple"
   pip install -r requirements.txt --index-url "${PYPI_INDEX}" \
     --trusted-host "${JFROG_URL#https://}"
   ```

**Success indicator**: Install succeeds; `{nickname}-pypi-ai-remote` cache has content.

**Key concept**: Pointing pip at Artifactory means all AI package installs — numpy, torch, transformers, huggingface — are governed by Curation policies. Developers don't change their workflow; the security gate enforces automatically.

---

### curation-ai-T3 — Create a Curation Policy for AI Packages (20 pts)

**Goal**: Create a Curation policy targeting your PyPI AI remote repository.

**Steps**:

1. JFrog UI → Curation → Policies → **New Policy**
2. Fill in:
   - **Name**: `{NICKNAME}-ai-curation` (must contain your nickname)
   - **Repository**: select `{NICKNAME}-pypi-ai-remote`
3. Add rule: CVE severity = Block if High/Critical, optionally add malicious package rule
4. Save

**Success indicator**: Policy visible in Curation → Policies list with your nickname.

**Key concept**: AI packages carry unique supply chain risks — malicious model weights, backdoored training pipelines, typosquatted packages mimicking popular ML libraries. Curation is the first line of defense before any AI package enters the internal network.

---

### curation-ai-T4 — Block a Vulnerable AI Package Version (20 pts)

**Goal**: Attempt to install an older AI package version that your Curation policy will block.

**Steps**:

Try installing a vulnerable older numpy version:
```bash
PYPI_INDEX="${JFROG_URL}/artifactory/api/pypi/${NICKNAME}-pypi-ai-virtual/simple"
pip install "numpy==1.21.0" --index-url "${PYPI_INDEX}" \
  --trusted-host "${JFROG_URL#https://}"
```

Or try:
```bash
pip install "torch==1.12.0" --index-url "${PYPI_INDEX}" \
  --trusted-host "${JFROG_URL#https://}"
```

**Success indicator**: Curation Audit shows a blocked PyPI entry from `{nickname}-pypi-ai-remote`.

**If the install is not blocked**: Confirm the policy is applied to `{nickname}-pypi-ai-remote`; wait 1-2 minutes; try even older versions.

---

### curation-ai-T5 — Review AI Package Governance in Curation Audit (20 pts)

**Goal**: Explore the Curation Audit log to understand the complete AI package governance trail.

**Steps**:

1. JFrog UI → Curation → Audit
2. Find records from your PyPI repositories
3. Explore:
   - **Allowed packages**: AI packages that passed Curation checks
   - **Blocked packages**: versions that triggered the policy
   - **Block reason**: CVE details, malicious package flags

**This task is manually verified — explore the UI then run the progress check to claim points.**

**Key concept**: For AI/ML teams, the Curation Audit log is compliance evidence — every package download is recorded, every block has a reason. This is how you prove to your security team that "we only used vetted AI packages."

---

## Troubleshooting

**pip install returns 401**: Confirm the Artifactory URL and token are correct; the PyPI index URL format must end with `/simple`.

**pip cannot reach Artifactory**: Check network access; confirm `{nickname}-pypi-ai-virtual` exists; verify the index URL is correct.

**Policy created but install not blocked**: Confirm the policy targets the correct remote repo; wait 1-2 minutes; try an older package version.

**Curation menu not visible**: Confirm the JFrog instance has Curation licensed; ask the instructor to verify.
