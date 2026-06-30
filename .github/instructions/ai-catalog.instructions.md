---
applyTo: "modules/ai-catalog/**"
---

# ai-catalog 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **ai-catalog** 模块。本模块聚焦于 JFrog AI Catalog：在 Artifactory 中创建 Hugging Face 仓库，通过 JFrog 发现和代理 AI 模型，用 Xray 扫描模型安全性，并创建 Curation 策略管控 AI 模型下载。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块目标

体验 JFrog AI Catalog 的完整工作流：
- 在 Artifactory 中创建 Hugging Face 类型仓库（作为 Hugging Face 的代理层）
- 通过 JFrog AI Catalog UI 浏览可用 AI 模型
- 将 AI 模型下载路由到 Artifactory（提供缓存、扫描、审计能力）
- 用 Xray 扫描 AI 模型，检测恶意代码和安全问题
- 创建 Curation 策略，防止危险 AI 模型进入开发环境

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| ai-catalog-T1 | 在 Artifactory 中创建 Hugging Face 仓库 | 10 | `{nickname}-hf-virtual` 仓库存在 |
| ai-catalog-T2 | 浏览 AI Catalog 并发现可用模型 | 20 | 手动验证 |
| ai-catalog-T3 | 通过 Artifactory 下载 AI 模型 | 20 | `{nickname}-hf-remote` 缓存有内容 |
| ai-catalog-T4 | 使用 Xray 扫描 AI 模型并查看安全报告 | 20 | 手动验证 |
| ai-catalog-T5 | 创建 Curation Policy 管控 AI 模型下载 | 20 | Curation 策略名称包含昵称 |
| **总计** | | **90** | |

**前置条件**：Python 3 + pip 已安装；JFrog 实例已启用 AI Catalog 功能。

---

## 任务详情

### ai-catalog-T1 — 创建 Hugging Face 仓库（10 分）

**目标**：在 Artifactory 中创建 `huggingfaceml` 类型的三层仓库，作为 Hugging Face 的代理层。

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/ai-catalog/create-repo.sh $NICKNAME
```

预期结果：
```
Creating Artifactory repositories for <nickname> (ai-catalog)...
    ✅ Created: <nickname>-hf-local
    ✅ Created: <nickname>-hf-remote
    ✅ Created: <nickname>-hf-virtual
✅ Repositories ready for <nickname>
```

**知识点**：JFrog 将 Hugging Face 作为一种包类型（`huggingfaceml`）支持，与 npm/Maven/Docker 并列。Remote 仓库代理 `https://huggingface.co`，所有模型下载流量都通过 Artifactory，实现统一缓存、扫描和审计。

---

### ai-catalog-T2 — 浏览 AI Catalog（20 分）

**目标**：在 JFrog UI 的 AI Catalog 中发现可用模型，了解 JFrog 对 AI 资产的可视化管理能力。

**步骤**：

1. 登录 JFrog UI
2. 在左侧导航栏中找到 **AI Catalog**
3. 浏览可用模型列表（按 Library、Task 类型、许可证等维度筛选）
4. 点击一个模型，查看其详细信息：模型架构、许可证、安全状态
5. 记下一个你感兴趣的模型名称（将在 T3 中下载）

**成功标志**：你浏览了 AI Catalog 并找到至少一个感兴趣的模型。此为手动验证任务。

**知识点**：AI Catalog 集成了 Hugging Face 的模型元数据，但将下载路由到你的 Artifactory 实例。这意味着所有模型都经过 JFrog 的安全扫描和准入控制，不再直接从公网拉取。

---

### ai-catalog-T3 — 下载 AI 模型（20 分）

**目标**：将 AI 模型下载路由到 Artifactory，验证模型通过 JFrog 代理下载并缓存。

**方式一（推荐）：使用示例脚本**

```bash
# 先安装依赖
pip install huggingface_hub

# 下载一个超小型测试模型
python3 modules/ai-catalog/sample-project/download_model.py $NICKNAME
```

**方式二：使用 huggingface-cli**

```bash
pip install huggingface_hub

# 设置 Artifactory 为 HuggingFace 端点
export HF_ENDPOINT="${JFROG_URL}/artifactory/api/huggingface/${NICKNAME}-hf-virtual"
export HF_TOKEN=$JFROG_TOKEN

huggingface-cli download hf-internal-testing/tiny-random-BertModel
```

**成功标志**：命令完成后，`{nickname}-hf-remote` 仓库中有缓存的模型文件。

在 JFrog UI 确认：**Artifactory → Repositories → `{nickname}-hf-remote`** → 有内容。

---

### ai-catalog-T4 — Xray 扫描 AI 模型（20 分）

**目标**：查看 Xray 对下载的 AI 模型的安全扫描结果。

**步骤**：

1. 在 JFrog UI 中进入：**Artifactory → Repositories → `{nickname}-hf-remote`**
2. 浏览到已下载的模型文件（`.safetensors`、`.bin` 等格式）
3. 点击文件，查看右侧的 **Xray** 标签
4. 查看扫描结果：
   - **Malicious code**：是否包含恶意代码
   - **CVEs**：依赖或嵌入代码的漏洞
   - **License**：许可证合规性

**成功标志**：你查看了模型的 Xray 扫描报告。此为手动验证任务。

**知识点**：JFrog Xray 支持扫描 AI 模型文件格式（Pickle、SafeTensors、GGUF 等），检测序列化数据中的恶意代码。Pickle 格式的模型文件可以嵌入任意 Python 代码，是已知的 AI 供应链攻击向量。

---

### ai-catalog-T5 — 创建 Curation Policy（20 分）

**目标**：创建 Curation 策略，设置 AI 模型下载的准入规则。

**步骤**：

1. 在 JFrog UI 中进入：**Curation → Policies → New Policy**
2. 配置：
   - **Policy Name**：`{NICKNAME}-ai-curation`（必须包含你的昵称）
   - **Package Type**：Hugging Face
   - **Repositories**：选择 `{nickname}-hf-remote`
   - **Rules**：添加规则 — 阻断包含恶意代码指标的模型
3. 点击 **Save & Apply**

**成功标志**：Curation 策略列表中出现 `{nickname}-ai-curation`。

**知识点**：Curation 对 AI 模型的准入控制类似于对 npm 包的控制。企业可以设置规则：只允许经过扫描且无恶意代码的模型进入开发环境，防止 AI 供应链攻击。

---

## 故障排查

**AI Catalog 导航找不到**：确认 JFrog 版本支持 AI Catalog（需要 7.x 以上）；联系讲师确认实例已启用该功能。

**下载脚本报 "Not Found"**：确认 `HF_ENDPOINT` URL 正确；确认 `{nickname}-hf-virtual` 仓库已创建（T1）；确认 `JFROG_TOKEN` 有 Read 权限。

**模型下载很慢**：使用 `hf-internal-testing/tiny-random-BertModel` 等超小型模型（< 1MB）作为演示；生产环境大模型（几GB）不适合在 Workshop 中使用。

**Xray 扫描结果为空**：等待 1-2 分钟让 Xray 完成扫描；确认仓库创建时 `xrayIndex: true` 已设置（`create-repo.sh` 已处理）。
