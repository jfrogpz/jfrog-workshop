---
applyTo: "modules/curation-docker/**"
---

# curation-docker 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **curation-docker** 模块。本模块聚焦于 Docker 镜像供应链防护：通过 Artifactory Curation 拉取镜像，创建 Curation 策略阻断不合规的基础镜像，并在 Audit 日志中查看拦截记录。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块目标

使用 JFrog Curation 在镜像拉取阶段防护 Docker 供应链：所有 `docker pull` 通过 Artifactory 虚拟仓库路由，Curation 策略在镜像进入内网前拦截含高危 CVE 或不合规的镜像。

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| curation-docker-T1 | 在 Artifactory 中创建个人 Docker 仓库 | 10 | `{nickname}-docker-curated-virtual` 仓库存在 |
| curation-docker-T2 | 通过 Artifactory Curation 拉取 Docker 镜像 | 20 | `{nickname}-docker-curated-remote` 缓存中有内容 |
| curation-docker-T3 | 创建 Docker Curation 策略 | 20 | 策略名称包含昵称 |
| curation-docker-T4 | 触发 Curation 阻断不合规镜像 | 20 | Curation Audit 中有 Docker 阻断记录（含昵称仓库）|
| curation-docker-T5 | 在 Curation Audit 中查看被阻断的镜像 | 20 | 手动验证（UI 探索）|
| **总计** | | **90** | |

**前置条件**：JFrog 实例已启用 Curation；Docker 已安装；实例域名可用于 Docker 拉取。

---

## 任务详情

### curation-docker-T1 — 在 Artifactory 中创建个人 Docker 仓库（10 分）

**目标**：创建三个 Docker 仓库（local / remote / virtual），其中 remote 仓库启用 Curation。

**步骤**：

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/curation-docker/create-repo.sh $NICKNAME
```

预期输出：
```
Creating Artifactory repositories for <nickname> (curation-docker)...
    ✅ Created: <nickname>-docker-curated-local
    ✅ Created: <nickname>-docker-curated-remote
    ✅ Created: <nickname>-docker-curated-virtual
✅ Repositories ready for <nickname>
```

**成功标志**：三个仓库在 JFrog UI → Artifactory → Repositories 中可见，remote 仓库已标记 Curated。

---

### curation-docker-T2 — 通过 Artifactory Curation 拉取 Docker 镜像（20 分）

**目标**：将 Docker 的拉取请求路由经过 Artifactory，验证镜像流经 Curation 管道。

**步骤**：

1. 配置 JFrog CLI（如已配置可跳过）：
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

2. 登录 Artifactory Docker 虚拟仓库：
   ```bash
   docker login ${JFROG_URL#https://} -u $NICKNAME -p $JFROG_TOKEN
   ```

3. 通过 Artifactory 拉取镜像：
   ```bash
   DOCKER_REGISTRY="${JFROG_URL#https://}/docker"
   docker pull ${DOCKER_REGISTRY}/${NICKNAME}-docker-curated-virtual/python:3.9-slim
   ```

**成功标志**：拉取成功，`{nickname}-docker-curated-remote` 缓存中有内容。

**知识点**：将 Docker 客户端指向 Artifactory 虚拟仓库后，所有 `docker pull` 都经过 Curation 检查——即使开发者不感知，安全策略已在后台生效。

---

### curation-docker-T3 — 创建 Docker Curation 策略（20 分）

**目标**：创建一个针对 Docker 镜像的 Curation 策略，定义阻断条件。

**步骤**：

1. JFrog UI → Curation → Policies → **New Policy**
2. 填写：
   - **Name**：`{NICKNAME}-docker-curation`（名称必须包含昵称）
   - **Repository**：选择 `{NICKNAME}-docker-curated-remote`
3. 添加规则（选择以下之一或多个）：
   - CVE severity：Block if High/Critical CVEs detected
   - Malicious package：Block known malicious packages
4. 保存策略

**成功标志**：策略在 Curation → Policies 列表中可见，名称包含你的昵称。

**知识点**：Curation 策略在镜像**下载到内网之前**就执行检查，比 Xray 扫描更早介入供应链——Xray 扫描已存在的内容，Curation 阻止不合规内容进入。

---

### curation-docker-T4 — 触发 Curation 阻断不合规镜像（20 分）

**目标**：尝试拉取一个会被 Curation 策略阻断的镜像，验证策略生效。

**步骤**：

尝试拉取含已知漏洞的旧版 Python 镜像：
```bash
DOCKER_REGISTRY="${JFROG_URL#https://}/docker"
docker pull ${DOCKER_REGISTRY}/${NICKNAME}-docker-curated-virtual/python:3.8
```

如果策略配置正确，拉取会被拒绝并提示类似：
```
Error response from daemon: pull access denied ... blocked by Curation policy
```

**成功标志**：Curation Audit 中出现来自 `{nickname}-docker-curated-remote` 的 blocked 记录。

**如果没有被阻断**：
- 确认步骤 T3 的策略已应用到 `{nickname}-docker-curated-remote`
- 在策略规则中确认 Min CVE Severity 设置为 High 或 Critical
- 可以尝试其他老旧版本如 `python:2.7` 或 `python:3.6`

---

### curation-docker-T5 — 在 Curation Audit 中查看被阻断的镜像（20 分）

**目标**：在 Curation Audit 界面中探索拦截日志，理解阻断原因和违规详情。

**步骤**：

1. JFrog UI → Curation → Audit
2. 找到被阻断的拉取记录（含你的昵称仓库）
3. 查看：
   - **被阻断的镜像**：名称和版本
   - **阻断原因**：触发的策略规则（CVE、恶意包等）
   - **CVE 详情**：如果是因 CVE 阻断，可查看具体漏洞信息

**本任务为手动验证，探索完 UI 后直接运行进度检查即可得分。**

**知识点**：Curation Audit 日志是向安全团队证明供应链合规的重要证据——每一次阻断都有完整记录，包括时间、镜像、触发规则和 CVE 详情。

---

## 故障排查

**Docker login 失败**：确认域名不含 `https://`；确认 Token 有效。

**拉取时提示 repository does not exist**：确认虚拟仓库名称拼写正确；确认 `create-repo.sh` 已成功运行。

**策略创建后拉取仍未被阻断**：确认策略已选择正确的 remote 仓库；等待 1-2 分钟让策略生效；尝试更老的镜像版本（如 `python:2.7`）。

**看不到 Curation 菜单**：确认 JFrog 实例已启用 Curation 功能；联系讲师确认环境配置。
