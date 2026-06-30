---
applyTo: "modules/ai-catalog/**"
---

# ai-catalog Module — AI Assistant Guide

You are guiding a participant through the **ai-catalog** module of the JFrog Workshop. This module focuses on JFrog AI Catalog: create Hugging Face repositories in Artifactory, browse and proxy AI models through JFrog, scan models with Xray, and create Curation policies to govern AI model downloads.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Experience the full JFrog AI Catalog workflow:
- Create Hugging Face repositories in Artifactory (as a proxy layer for HuggingFace)
- Browse available AI models through the JFrog AI Catalog UI
- Route AI model downloads through Artifactory for caching, scanning, and auditing
- Scan AI model files with Xray to detect malicious code and security issues
- Create a Curation policy to prevent dangerous AI models from entering the development environment

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| ai-catalog-T1 | Create a Hugging Face repository in Artifactory | 10 | `{nickname}-hf-virtual` repo exists |
| ai-catalog-T2 | Browse AI Catalog and discover available models | 20 | Manual verification |
| ai-catalog-T3 | Download an AI model through Artifactory | 20 | `{nickname}-hf-remote` cache has content |
| ai-catalog-T4 | Scan the AI model with Xray | 20 | Manual verification |
| ai-catalog-T5 | Create a Curation Policy to govern AI model downloads | 20 | Curation policy name contains nickname |
| **Total** | | **90** | |

**Prerequisites**: Python 3 and pip installed; JFrog instance with AI Catalog feature enabled.

---

## Task Details

### ai-catalog-T1 — Create Hugging Face Repositories (10 pts)

**Goal**: Create three-tier `huggingfaceml` repositories in Artifactory as a proxy layer for Hugging Face.

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/ai-catalog/create-repo.sh $NICKNAME
```

Expected output:
```
Creating Artifactory repositories for <nickname> (ai-catalog)...
    ✅ Created: <nickname>-hf-local
    ✅ Created: <nickname>-hf-remote
    ✅ Created: <nickname>-hf-virtual
✅ Repositories ready for <nickname>
```

**Key concept**: JFrog treats Hugging Face as a first-class package type (`huggingfaceml`), alongside npm/Maven/Docker. The remote repository proxies `https://huggingface.co` so all model downloads flow through Artifactory — enabling unified caching, scanning, and audit.

---

### ai-catalog-T2 — Browse AI Catalog (20 pts)

**Goal**: Use the JFrog AI Catalog UI to discover available models and understand JFrog's visibility into AI assets.

**Steps**:

1. Log in to the JFrog UI
2. Find **AI Catalog** in the left navigation sidebar
3. Browse the model list (filter by Library, Task type, license, etc.)
4. Click a model to view its details: architecture, license, security status
5. Note a model you want to download in T3

**Success indicator**: You browsed AI Catalog and found at least one model of interest. This is a manual verification task.

**Key concept**: AI Catalog integrates Hugging Face model metadata while routing downloads through your Artifactory instance. All models go through JFrog's security controls — no direct public internet access from developer machines.

---

### ai-catalog-T3 — Download an AI Model (20 pts)

**Goal**: Route an AI model download through Artifactory to demonstrate caching and audit capability.

**Option 1 (recommended) — sample script**:

```bash
pip install huggingface_hub
python3 modules/ai-catalog/sample-project/download_model.py $NICKNAME
```

**Option 2 — huggingface-cli**:

```bash
pip install huggingface_hub

export HF_ENDPOINT="${JFROG_URL}/artifactory/api/huggingface/${NICKNAME}-hf-virtual"
export HF_TOKEN=$JFROG_TOKEN

huggingface-cli download hf-internal-testing/tiny-random-BertModel
```

**Success indicator**: After download completes, `{nickname}-hf-remote` cache has content.

Verify in JFrog UI: **Artifactory → Repositories → `{nickname}-hf-remote`** → has files.

---

### ai-catalog-T4 — Scan AI Model with Xray (20 pts)

**Goal**: View Xray security scan results for the downloaded AI model.

**Steps**:

1. In JFrog UI: **Artifactory → Repositories → `{nickname}-hf-remote`**
2. Browse to a downloaded model file (`.safetensors`, `.bin`, etc.)
3. Click the file, then open the **Xray** tab
4. Review:
   - **Malicious code**: embedded malicious logic detection
   - **CVEs**: vulnerabilities in dependencies or embedded code
   - **License**: license compliance

**Success indicator**: You viewed the Xray scan report for the model. This is a manual verification task.

**Key concept**: JFrog Xray scans AI model file formats including Pickle, SafeTensors, and GGUF — detecting malicious code in serialized data. Pickle-format models can embed arbitrary Python code, making them a known AI supply chain attack vector.

---

### ai-catalog-T5 — Create a Curation Policy (20 pts)

**Goal**: Create a Curation policy that enforces AI model download governance.

**Steps**:

1. In JFrog UI: **Curation → Policies → New Policy**
2. Configure:
   - **Policy Name**: `{NICKNAME}-ai-curation` (must contain your nickname)
   - **Package Type**: Hugging Face
   - **Repositories**: select `{nickname}-hf-remote`
   - **Rules**: add a rule to block models with malicious indicators
3. Click **Save & Apply**

**Success indicator**: `{nickname}-ai-curation` appears in the Curation policies list.

**Key concept**: Curation for AI models works the same way as for npm or PyPI packages — it enforces governance rules at download time. Organizations can set rules to allow only scanned, malicious-code-free models into the development environment, preventing AI supply chain attacks.

---

## Troubleshooting

**AI Catalog not visible in sidebar**: Confirm the JFrog version supports AI Catalog (requires 7.x+); ask the instructor to verify the feature is enabled on the instance.

**Download script returns "Not Found"**: Confirm the `HF_ENDPOINT` URL is correct; confirm `{nickname}-hf-virtual` was created (T1); confirm `JFROG_TOKEN` has Read permission.

**Model download is very slow**: Use tiny test models like `hf-internal-testing/tiny-random-BertModel` (< 1 MB) for the workshop demo — production-size models (several GB) are not suitable.

**Xray scan results empty**: Wait 1-2 minutes for Xray to complete scanning; confirm repositories were created with `xrayIndex: true` (`create-repo.sh` handles this).
