---
applyTo: "modules/curation-ai/**"
---

# curation-ai 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **curation-ai** 模块。本模块聚焦于 AI/ML 包的供应链治理：通过 Artifactory Curation 管控 PyPI AI 依赖包（如 numpy、torch 等），防止含漏洞的 AI 包进入内网，并在 Audit 中查看完整的治理记录。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块目标

使用 JFrog Curation 对 AI/ML 包进行供应链治理：将 pip 安装请求路由经 Artifactory，建立 PyPI Curation 策略阻断含高危 CVE 的 AI 包版本，并通过 Audit 日志证明治理有效性。

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| curation-ai-T1 | 创建 Curated PyPI 仓库用于 AI 包管理 | 10 | `{nickname}-pypi-ai-virtual` 仓库存在 |
| curation-ai-T2 | 通过 Artifactory Curation 安装 AI 依赖包 | 20 | `{nickname}-pypi-ai-remote` 缓存有内容 |
| curation-ai-T3 | 为 AI 包创建 Curation 策略 | 20 | 策略名称包含昵称 |
| curation-ai-T4 | 阻断一个存在漏洞的 AI 包版本 | 20 | Curation Audit 有 PyPI 阻断记录（含昵称仓库）|
| curation-ai-T5 | 在 Curation Audit 中查看 AI 包治理记录 | 20 | 手动验证（UI 探索）|
| **总计** | | **90** | |

**前置条件**：JFrog 实例已启用 Curation；已安装 Python 3 和 pip；pip 可访问 Artifactory PyPI 仓库。

---

## 任务详情

### curation-ai-T1 — 创建 Curated PyPI 仓库（10 分）

**目标**：创建三个 PyPI 仓库（local / remote / virtual），其中 remote 启用 Curation 拦截。

**步骤**：

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/curation-ai/create-repo.sh $NICKNAME
```

预期输出：
```
Creating Artifactory repositories for <nickname> (curation-ai)...
    ✅ Created: <nickname>-pypi-ai-local
    ✅ Created: <nickname>-pypi-ai-remote
    ✅ Created: <nickname>-pypi-ai-virtual
✅ Repositories ready for <nickname>
```

**成功标志**：三个仓库在 JFrog UI → Artifactory → Repositories 可见，remote 仓库标记为 Curated。

---

### curation-ai-T2 — 通过 Artifactory Curation 安装 AI 依赖包（20 分）

**目标**：将 pip 安装请求路由经 Artifactory Curation，验证 AI 包流经治理管道。

**步骤**：

1. 配置 JFrog CLI（如已配置可跳过）：
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

2. 进入示例项目并安装依赖：
   ```bash
   cd modules/curation-ai/sample-project
   PYPI_INDEX="${JFROG_URL}/artifactory/api/pypi/${NICKNAME}-pypi-ai-virtual/simple"
   pip install -r requirements.txt --index-url "${PYPI_INDEX}" \
     --trusted-host "${JFROG_URL#https://}"
   ```

**成功标志**：安装成功，`{nickname}-pypi-ai-remote` 缓存中有内容。

**知识点**：将 pip 指向 Artifactory 虚拟仓库后，所有 `pip install` 都经过 Curation 检查。对 AI/ML 团队而言，这意味着 numpy、torch、transformers 等所有 AI 包都受到统一的安全管控，而不依赖开发者的个人安全意识。

---

### curation-ai-T3 — 为 AI 包创建 Curation 策略（20 分）

**目标**：创建针对 PyPI AI 包的 Curation 策略，定义阻断条件。

**步骤**：

1. JFrog UI → Curation → Policies → **New Policy**
2. 填写：
   - **Name**：`{NICKNAME}-ai-curation`（名称必须包含昵称）
   - **Repository**：选择 `{NICKNAME}-pypi-ai-remote`
3. 添加规则：
   - CVE severity：Block if High/Critical CVEs detected
   - 可选：Malicious package rule
4. 保存策略

**成功标志**：策略在 Curation → Policies 列表可见，名称包含你的昵称。

**知识点**：AI 包的供应链风险与传统软件包不同——AI 模型权重、恶意训练数据、后门模型都可能通过包管理器传播。Curation 是 AI/ML 供应链安全的第一道防线。

---

### curation-ai-T4 — 阻断一个存在漏洞的 AI 包版本（20 分）

**目标**：尝试安装一个含已知漏洞的旧版 AI 包，验证 Curation 策略阻断生效。

**步骤**：

尝试安装含已知漏洞的旧版 numpy：
```bash
PYPI_INDEX="${JFROG_URL}/artifactory/api/pypi/${NICKNAME}-pypi-ai-virtual/simple"
pip install "numpy==1.21.0" --index-url "${PYPI_INDEX}" \
  --trusted-host "${JFROG_URL#https://}"
```

如果策略配置正确，安装会被拒绝并提示 Curation 阻断。

也可以尝试：
```bash
pip install "torch==1.12.0" --index-url "${PYPI_INDEX}" \
  --trusted-host "${JFROG_URL#https://}"
```

**成功标志**：Curation Audit 中出现来自 `{nickname}-pypi-ai-remote` 的 PyPI blocked 记录。

**如果没有被阻断**：确认策略已应用到正确的 remote 仓库；确认策略规则设置为 High/Critical；等待 1-2 分钟让策略生效。

---

### curation-ai-T5 — 在 Curation Audit 中查看 AI 包治理记录（20 分）

**目标**：在 Curation Audit 中探索 AI 包的完整治理日志，理解合规证据链。

**步骤**：

1. JFrog UI → Curation → Audit
2. 查找你的 PyPI 仓库相关记录
3. 探索：
   - **允许的包**：通过 Curation 检查的 AI 包
   - **被阻断的包**：触发策略的旧版本或含漏洞的包
   - **阻断原因**：CVE 详情、恶意包标记等

**本任务为手动验证，探索完 UI 后直接运行进度检查即可得分。**

**知识点**：对于 AI/ML 工程团队，Curation Audit 提供了向合规团队证明"我们只使用了经过安全审查的 AI 包"的完整证据——每一次包下载都有记录，每一次阻断都有原因。

---

## 故障排查

**pip install 报 401**：确认 Artifactory URL 和 Token 正确；在 pip 命令中添加 `--extra-index-url` 避免回退到官方 PyPI。

**pip 无法访问 Artifactory**：检查网络访问；确认 `{nickname}-pypi-ai-virtual` 已创建；确认 PyPI 仓库的 index URL 格式正确（需以 `/simple` 结尾）。

**策略创建后安装仍未被阻断**：确认策略应用到了正确的 remote 仓库；等待 1-2 分钟；尝试更老版本的包。

**看不到 Curation 菜单**：确认 JFrog 实例已启用 Curation 许可证；联系讲师。
