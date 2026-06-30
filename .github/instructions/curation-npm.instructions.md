---
applyTo: "modules/curation-npm/**"
---

# curation-npm 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **curation-npm** 模块。本模块聚焦于 npm 供应链安全：制品代理、构建可追溯性和 Curation 策略拦截。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 背景：软件供应链攻击

近年来，供应链攻击已成为开发者面临的最隐蔽威胁之一：

- **ua-parser-js（2021）**：npm 账号被劫持，三个版本被植入挖矿程序和密码窃取器，短时间内波及全球
- **PyTorch（2022）**：恶意包通过依赖混淆攻击（dependency confusion）入侵，窃取敏感数据
- **polyfill.io（2024）**：cdn.polyfill.io 域名被收购后，CDN 开始向超过 10 万个网站推送恶意脚本，受影响站点毫不知情
- **lottie-player（2024）**：npm 包维护者账号被劫持，恶意版本自动推送给所有依赖方，植入加密钱包窃取器
- **tj-actions/changed-files（2025）**：广泛使用的 GitHub Actions 组件被植入后门，导致大量 CI/CD 流水线泄露密钥

这些攻击的共同点：**开发者在不知情的情况下将恶意代码引入了生产环境**。

---

## 企业中谁会受影响？JFrog 如何解决？

### 受影响的角色

| 角色 | 痛点 |
|------|------|
| **开发者** | 不知道用的包是否安全，修复漏洞时不知道影响范围 |
| **安全团队** | 无法在包进入构建前拦截，只能事后扫描 |
| **DevOps / 平台团队** | 缺乏统一的制品管控，难以追溯"谁用了什么版本" |

### JFrog 的解决方案

- **JFrog Artifactory**：统一的制品代理，所有依赖必须经过 Artifactory 仓库，形成"护城河"
- **JFrog Curation**：在依赖**下载阶段**自动拦截已知恶意包和高危漏洞——比构建后扫描早一步
- **JFrog Xray**：深度扫描已有制品和 build-info，提供 CVE 分析、许可证合规检查
- **Build Info**：记录每次构建的完整依赖树，支持快速溯源和影响范围分析

📖 了解更多：[JFrog Curation 文档](https://jfrog.com/help/r/jfrog-curation) | [JFrog Xray 文档](https://jfrog.com/help/r/jfrog-xray)

---

## 模块目标

通过动手实践，体验从"引入恶意依赖"到"检测 → 阻断 → 修复"的完整供应链安全闭环。

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| curation-npm-T1 | 在 Artifactory 中创建个人 npm 仓库 | 10 | Artifactory 中存在 `{nickname}-npm-dev-virtual` 仓库 |
| curation-npm-T2 | 完成首次 npm build | 20 | `{nickname}-npm-org-remote` 中有缓存的包 |
| curation-npm-T3 | 发布 Build #1 build-info | 20 | Artifactory 中 Build `{nickname}-npm-sample #1` 存在 |
| curation-npm-T4 | 创建 Curation Policy | 10 | 系统中存在包含学员昵称的 Curation Policy |
| curation-npm-T5 | 触发 Curation 阻断 axios@1.7.2 | 20 | Curation 审计日志中有 axios@1.7.2 被阻断的记录 |
| curation-npm-T6 | 修复问题并完成 Build #3 | 20 | Artifactory 中 Build `{nickname}-npm-sample #3` 存在，且 axios 版本不是 1.7.2 |
| **总计** | | **100** | |

**前置条件**：JFrog 实例上必须已启用 Curation 功能，并配置为支持 npm 包。

---

## 任务详情

### curation-npm-T1 — 在 Artifactory 中创建个人 npm 仓库（10 分）

**目标**：在 Artifactory 上创建专属的 npm 仓库组（本地仓库、远程代理仓库、虚拟仓库）。

**步骤**：
1. 运行仓库创建脚本：
   ```bash
   bash modules/curation-npm/create-repo.sh <NICKNAME>
   ```
2. 确认以下三个仓库已创建：`{nickname}-npm-dev-local`、`{nickname}-npm-org-remote`、`{nickname}-npm-dev-virtual`

**成功标志**：三个仓库在 Artifactory UI 中可见。

---

### curation-npm-T2 — 首次 npm build（20 分）

**目标**：配置本地 npm 通过 Artifactory 解析依赖，完成 npm install 并缓存包。

**步骤**：
1. 配置 JFrog CLI：
   ```bash
   jf config add workshop --url=<JFROG_URL> --access-token=<JFROG_TOKEN> --interactive=false
   jf config use workshop
   ```
2. 进入示例项目并配置 npm 指向 Artifactory 仓库：
   ```bash
   cd modules/curation-npm/sample-project
   jf npmc --repo-resolve <NICKNAME>-npm-dev-virtual --repo-deploy <NICKNAME>-npm-dev-local
   ```
3. 执行安装：
   ```bash
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=1
   ```

**成功标志**：Artifactory 的 `{nickname}-npm-org-remote` 中有缓存的包。

---

### curation-npm-T3 — 发布 Build #1 Build Info（20 分）

**目标**：将构建元数据发布到 Artifactory，建立供应链可追溯性。

**步骤**：
1. 发布 build-info：
   ```bash
   jf rt build-publish <NICKNAME>-npm-sample 1
   ```
2. 在 JFrog UI 中验证：Builds → `{nickname}-npm-sample` → Build #1

**成功标志**：Artifactory 中 Build #1 可查询。

**知识点**：build-info 记录了完整的依赖树，是供应链溯源的基础。

---

### curation-npm-T4 — 创建 Curation Policy（10 分）

**目标**：为个人 Artifactory 仓库创建 Curation 策略，阻断已知风险包。

**步骤**：
1. 在 JFrog UI 中：Curation → Policies → New Policy
2. 配置：
   - Name：`{nickname}-npm-policy`（必须包含昵称）
   - Policy Action：Block
3. 创建自定义 Condition：
   - 点击 **New Condition**
   - Condition Name：`{nickname}-block-axios-172`
   - Package Type：**npm**
   - Condition Type：**Specific Versions**
   - Package Name：`axios`
   - Package Versions：`1.7.2`
4. 开启 **Enforce policy on cached packages**
5. Apply to：`{nickname}-npm-org-remote`（注意：选远程代理仓库，不是 virtual）
6. 保存——确认 Policy 状态为 **Enabled**

**成功标志**：系统中存在包含学员昵称的 Curation Policy。

**知识点**：真实场景中，JFrog Curation 会自动识别已知恶意包，无需手动指定版本。这里用特定版本模拟演示。

---

### curation-npm-T5 — 触发 Curation 阻断 axios@1.7.2（20 分）

**目标**：尝试安装模拟恶意包 `axios@1.7.2`，验证 Curation 策略生效。

**步骤**：
1. `package.json` 中 axios 已是 `1.7.2`，无需修改
2. 清除 Artifactory 远程仓库缓存：
   ```bash
   bash modules/curation-npm/clear-remote-cache.sh
   ```
3. 触发拦截：
   ```bash
   cd modules/curation-npm/sample-project
   rm -rf node_modules package-lock.json
   npm cache clean --force
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=2
   ```
4. 观察错误信息——Curation 已阻断 axios@1.7.2

**成功标志**：Curation 审计日志中有 axios@1.7.2 被阻断的记录。

**知识点**：Curation 充当"海关"角色，在包进入构建环境前拦截恶意版本。

---

### curation-npm-T6 — 修复并完成 Build #3（20 分）

**目标**：将 axios 升级为安全版本，重新构建并发布 Build #3。

**步骤**：
1. 修复版本：
   ```bash
   cd modules/curation-npm/sample-project
   sed -i 's/"axios": "1.7.2"/"axios": "1.7.7"/' package.json
   grep axios package.json
   ```
2. 重新构建（build-number 为 3，跳过被阻断的 2）：
   ```bash
   rm -rf node_modules package-lock.json
   npm cache clean --force
   jf npm install --build-name=<NICKNAME>-npm-sample --build-number=3
   ```
3. 发布：
   ```bash
   jf rt build-publish <NICKNAME>-npm-sample 3
   ```

**成功标志**：Artifactory 中 Build #3 存在，且 axios 版本不是 1.7.2。

**知识点**：完整的供应链安全闭环：代理（Artifactory）→ 检测（Xray）→ 预防（Curation）→ 修复 → 验证（build-info）。

---

## 故障排查

**npm install 超时或报错**：检查 `jf config show` 确认 URL 和 Token 正确；确认虚拟仓库指向了正确的远程代理仓库。

**Curation Policy 不生效**：确认 Policy 已激活（Enabled），已开启 **Enforce policy on cached packages**，且 Apply to 选择的是远程代理仓库（`{nickname}-npm-org-remote`），而不是 virtual 仓库。


