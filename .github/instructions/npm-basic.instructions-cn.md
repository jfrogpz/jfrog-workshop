---
applyTo: "modules/npm-basic/**"
---

# npm-basic 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **npm-basic** 模块。本模块聚焦于 npm 制品代理：设置个人 Artifactory 仓库并将 npm 构建流量路由至其中。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| npm-basic-T1 | 在 Artifactory 中创建个人 npm 仓库 | 10 | Artifactory 中存在 `{nickname}-npm-dev-virtual` 仓库 |
| npm-basic-T2 | 完成首次 npm build | 20 | `{nickname}-npm-org-remote-cache` 中有缓存的包 |
| **总计** | | **30** | |

**前置条件**：支持 npm 包类型的 JFrog Artifactory 实例，无需额外功能。

---

## 任务详情

### npm-basic-T1 — 在 Artifactory 中创建个人 npm 仓库（10 分）

**目标**：在 Artifactory 上创建专属的 npm 仓库组（本地仓库、远程代理仓库、虚拟仓库）。

**步骤**：

首先检查 profile 是否已加载：
```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
```

如果 `JFROG_URL` 和 `JFROG_TOKEN` 未设置，请学员提供后运行：
```bash
bash modules/npm-basic/create-repo.sh <NICKNAME>
```

确认以下三个仓库已创建：`{nickname}-npm-dev-local`、`{nickname}-npm-org-remote`、`{nickname}-npm-dev-virtual`

**成功标志**：三个仓库在 Artifactory UI 中可见。

---

### npm-basic-T2 — 首次 npm build（20 分）

**目标**：配置本地 npm 通过 Artifactory 解析依赖，完成 npm install 并缓存包。

**步骤**：
1. 配置 JFrog CLI：
   ```bash
   jf config add workshop --url=<JFROG_URL> --access-token=<JFROG_TOKEN> --interactive=false
   jf config use workshop
   ```
2. 进入示例项目并配置 npm 指向 Artifactory 仓库：
   ```bash
   cd modules/npm-basic/sample-project
   jf npmc --repo-resolve <NICKNAME>-npm-dev-virtual --repo-deploy <NICKNAME>-npm-dev-local
   ```
3. 执行安装：
   ```bash
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=1
   ```

**成功标志**：Artifactory 的 `{nickname}-npm-org-remote-cache` 中有缓存的包。

**知识点**：通过 Artifactory 代理 npm 流量，所有包都会被缓存——提供可见性、管控能力，以及上游源不可用时的容灾保障。

---

## 故障排查

**npm install 超时或报错**：检查 `jf config show` 确认 URL 和 Token 正确；确认虚拟仓库指向了正确的远程代理仓库。

**仓库未创建成功**：确认 `JFROG_URL` 和 `JFROG_TOKEN` 已设置，且 Token 有创建仓库的权限。
