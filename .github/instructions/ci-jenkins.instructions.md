---
applyTo: "modules/ci-jenkins/**"
---

# ci-jenkins 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **ci-jenkins** 模块。本模块聚焦于将 JFrog 集成到 Jenkins CI 流水线：连接 Artifactory、发布制品、生成 Build Info、触发 Xray 安全扫描。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 背景：为什么 CI 流水线要集成 JFrog？

传统 CI 流水线（如 Jenkins）只负责"构建通过了吗"——但无法回答：

- 这次构建用了哪些依赖？版本是什么？
- 有没有依赖存在已知的 CVE？
- 三个月后，哪些服务使用了这个有漏洞的包？

JFrog 为 Jenkins 提供官方插件和 CLI 集成，把这些问题的答案内置进每一次构建：

- **Artifactory** 作为制品仓库，所有依赖必须经过它代理，形成统一入口
- **Build Info** 记录完整依赖树和构建元数据，每次构建可追溯
- **Xray** 在发布后自动扫描 Build Info，CVE 和许可证风险实时可见

📖 官方文档：[JFrog Jenkins Plugin](https://jfrog.com/help/r/jfrog-integrations-documentation/jenkins-artifactory-plug-in) | [JFrog CLI in Jenkins](https://docs.jfrog-applications.jfrog.io/jfrog-applications/ci-and-automation/jfrog-jenkins-plugin)

---

## 前置条件

在开始之前，确认以下条件就绪：

- Jenkins 实例可访问（本模块假设 Jenkins 地址由讲师提供或本地运行）
- 已有 Jenkins 管理员账号（用于安装插件）
- 已设置 `JFROG_URL` 和 `JFROG_TOKEN` 环境变量：
  ```bash
  source ~/.workshop-profile
  echo $JFROG_URL   # 应显示 JFrog 实例地址
  ```
- JFrog Xray 已在平台上启用（由讲师确认）

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| ci-jenkins-T1 | 将 Jenkins 连接到 JFrog Artifactory | 10 | Artifactory 中存在来自 Jenkins 的 Build Info 记录 |
| ci-jenkins-T2 | 创建 Artifactory 仓库 | 10 | `{nickname}-jenkins-npm-virtual` 仓库存在 |
| ci-jenkins-T3 | 运行流水线，构建并发布制品 | 20 | `{nickname}-jenkins-npm-local` 中有制品 |
| ci-jenkins-T4 | 从 Jenkins 发布 Build Info | 20 | Artifactory 中存在 `{nickname}-jenkins-build` |
| ci-jenkins-T5 | 对构建触发 Xray 扫描 | 20 | Xray 扫描状态为 completed |

---

## 任务详情

### ci-jenkins-T1 — 将 Jenkins 连接到 JFrog Artifactory（10 分）

**目标**：在 Jenkins 中安装 JFrog 官方插件，并配置 Artifactory 服务器连接。

#### 步骤一：安装 JFrog Jenkins 插件

1. 打开 Jenkins UI → **Manage Jenkins** → **Plugins** → **Available plugins**
2. 搜索 `JFrog`，找到 **JFrog** 插件（官方，by JFrog）
3. 勾选后点击 **Install**，等待安装完成
4. 安装完成后重启 Jenkins（或勾选"Restart Jenkins when installation is complete"）

> 📖 [插件安装文档](https://jfrog.com/help/r/jfrog-integrations-documentation/jenkins-artifactory-plug-in)

#### 步骤二：配置 Artifactory 服务器

1. 进入 **Manage Jenkins** → **System** → 找到 **JFrog** 部分
2. 点击 **Add JFrog Platform Instance**，填写：
   - **Instance ID**：`workshop`（后续 Jenkinsfile 中引用此名称）
   - **JFrog Platform URL**：`$JFROG_URL`（你的 JFrog 实例地址，如 `https://xxx.jfrog.io`）
3. 在 **Default Deployer Credentials** 下：
   - 点击 **Add** → **Jenkins**
   - Kind 选 **Secret text**
   - Secret 填入你的 `$JFROG_TOKEN`
   - ID 填 `jfrog-token`，Description 填 `JFrog Access Token`
   - 保存后在下拉框中选择刚创建的凭证
4. 点击 **Test Connection**，确认提示 **Found JFrog Artifactory ...**
5. 点击 **Save**

**成功标志**：Test Connection 显示绿色成功提示，包含 Artifactory 版本号。

---

### ci-jenkins-T2 — 创建 Artifactory 仓库（10 分）

**目标**：为 Jenkins 构建创建专属的 npm 仓库组（local / remote / virtual）。

在 Codespace 终端运行：

```bash
source ~/.workshop-profile
bash modules/ci-jenkins/create-repo.sh $NICKNAME
```

预期输出：
```
Creating Artifactory repositories for <nickname> (ci-jenkins)...
    ✅ Created: <nickname>-jenkins-npm-local
    ✅ Created: <nickname>-jenkins-npm-remote
    ✅ Created: <nickname>-jenkins-npm-virtual
✅ Repositories ready for <nickname>
```

**成功标志**：在 JFrog UI → Artifactory → Repositories 中能看到三个新仓库。

---

### ci-jenkins-T3 — 运行流水线，构建并发布制品（20 分）

**目标**：在 Jenkins 中创建流水线任务，使用 `modules/ci-jenkins/sample-project/Jenkinsfile` 运行构建并将制品发布到 Artifactory。

#### 步骤一：在 Jenkins 中配置凭证

Jenkins 流水线需要以下三个 Credentials（**Manage Jenkins** → **Credentials** → **Global** → **Add Credentials**）：

| ID | Kind | 值 | 说明 |
|----|------|---|------|
| `jfrog-url` | Secret text | `$JFROG_URL` 的值 | JFrog 实例地址 |
| `jfrog-token` | Secret text | `$JFROG_TOKEN` 的值 | Access Token |
| `jfrog-nickname` | Secret text | 你的昵称 | 用于区分个人仓库 |

> 提示：在终端运行 `echo $JFROG_URL` 和 `echo $JFROG_TOKEN` 获取当前值。

#### 步骤二：创建流水线任务

1. Jenkins 首页 → **New Item**
2. 名称填入：`<NICKNAME>-jfrog-workshop`
3. 类型选 **Pipeline** → **OK**
4. 在 **Pipeline** 配置区：
   - Definition 选 **Pipeline script from SCM**
   - SCM 选 **Git**
   - Repository URL 填入本仓库地址（由讲师提供，或 fork 后的地址）
   - Script Path 填：`modules/ci-jenkins/sample-project/Jenkinsfile`
5. 点击 **Save**

#### 步骤三：触发构建

点击 **Build Now**，观察 Console Output，确认：
- `jf config add` 成功（无报错）
- `jf rt ping` 返回 `OK`
- `jf npm install` 成功下载依赖
- Console 末尾显示 `Finished: SUCCESS`

**成功标志**：JFrog UI → Artifactory → `<NICKNAME>-jenkins-npm-local` 仓库下出现 npm 包文件。

---

### ci-jenkins-T4 — 从 Jenkins 发布 Build Info（20 分）

**目标**：确认 Jenkinsfile 的 `Publish Build Info` 阶段成功执行，Build Info 记录出现在 Artifactory。

Build Info 由 Jenkinsfile 中的以下步骤自动完成（无需额外操作）：

```groovy
jf rt build-collect-env "${BUILD_NAME}" "${BUILD_NUMBER}"
jf rt build-publish "${BUILD_NAME}" "${BUILD_NUMBER}"
```

#### 在 Artifactory UI 中验证

1. 打开 JFrog UI → **Artifactory** → 左侧菜单选 **Builds**
2. 找到名为 `<NICKNAME>-jenkins-build` 的条目
3. 点击进入，查看 Build Info 详情：
   - **Modules** 标签：显示本次构建的 npm 依赖列表
   - **Environment** 标签：显示 Jenkins 环境变量
   - **Published** 时间戳：对应 Jenkins 构建时间

**成功标志**：Artifactory → Builds 中存在 `<NICKNAME>-jenkins-build` 且能查看依赖详情。

> 📖 [Build Info 文档](https://jfrog.com/help/r/jfrog-cli/publishing-build-info)

---

### ci-jenkins-T5 — 对 Jenkins 构建触发 Xray 扫描（20 分）

**目标**：触发 Xray 对 Build Info 进行安全扫描，查看 CVE 和依赖风险报告。

Xray 扫描由 Jenkinsfile 中的以下步骤自动触发：

```groovy
jf rt build-scan --fail=false "${BUILD_NAME}" "${BUILD_NUMBER}"
```

`--fail=false` 表示即使发现漏洞也不中断流水线（适合学习场景）。

#### 在 Artifactory UI 中查看扫描结果

1. JFrog UI → **Artifactory** → **Builds** → `<NICKNAME>-jenkins-build`
2. 点击具体 Build Number
3. 切换到 **Xray Data** 标签
4. 查看：
   - **Security Issues**：已知 CVE 列表，含严重等级（Critical / High / Medium）
   - **License Issues**：依赖的许可证合规情况
   - 点击具体 CVE 可查看修复建议

#### 可选：在 Jenkins Console Output 中查看扫描摘要

构建日志中会输出 Xray 扫描摘要，例如：
```
[JFrog Xray] Xray scan completed successfully.
[JFrog Xray] Found 3 security issues.
```

**成功标志**：Artifactory → Builds → `<NICKNAME>-jenkins-build` 的 Xray Data 标签显示扫描完成。

---

## 故障排查

**Q：Test Connection 失败 / Connection refused**
- 检查 `JFrog Platform URL` 格式，末尾不要加 `/`，例如 `https://xxx.jfrog.io`
- 确认 Access Token 有效：`curl -H "Authorization: Bearer $JFROG_TOKEN" $JFROG_URL/artifactory/api/system/ping`
- 输出 `OK` 则 Token 有效，否则重新生成 Token

**Q：`jf rt ping` 在 Jenkins 中报 401**
- Credentials ID 填写是否与 Jenkinsfile 中的 `credentials('jfrog-token')` 一致
- 检查 Credentials 是否保存在 Global scope 下（而不是某个 Folder scope）

**Q：`jf npm install` 报 E404 / 找不到包**
- 确认 T2 已完成，`<NICKNAME>-jenkins-npm-virtual` 仓库存在
- Jenkinsfile 中 `VIRTUAL_REPO` 变量是否正确解析：查看 Console Output 中 `env.VIRTUAL_REPO` 的值

**Q：Build Info 在 Artifactory 中找不到**
- 确认 `jf rt build-publish` 步骤有执行（Console Output 中有无报错）
- Build Name 是否与查找的名称一致（包含 NICKNAME）

**Q：Xray Data 标签没有扫描结果**
- Xray 扫描是异步的，等待 1-2 分钟后刷新页面
- 确认平台已启用 Xray 并对该仓库配置了 Watch（由讲师在赛前配置）
