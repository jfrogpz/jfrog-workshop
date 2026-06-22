# NPM 供应链安全 Workshop

> 竞赛式 · AI 助理引导 · 实时排行榜

---

## 背景：npm 开源组件投毒事件

近年来，供应链攻击已成为开发者面临的最隐蔽威胁之一：

- **event-stream（2018）**：攻击者通过接手维护权，在包中植入窃取比特币钱包的代码，影响数百万下载量
- **ua-parser-js（2021）**：npm 账号被劫持，三个版本被植入挖矿程序和密码窃取器，短时间内波及全球
- **colors.js / faker.js（2022）**：作者故意破坏自己的包，数千个依赖该包的项目立刻崩溃
- **PyTorch（2022）**：恶意包通过依赖混淆攻击（dependency confusion）入侵，窃取敏感数据

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

## 本次 Workshop

### 目标
通过动手实践，体验从"引入恶意依赖"到"检测 → 阻断 → 修复"的完整供应链安全闭环。

### 时长
约 60 分钟

### 竞赛规则

| 任务 | 内容 | 分值 |
|------|------|------|
| T1 | 注册昵称并创建个人 Artifactory 仓库 | 10 分 |
| T2 | 完成首次 npm build | 20 分 |
| T3 | 发布 Build #1 build-info | 20 分 |
| T4 | 创建 Curation Policy | 10 分 |
| T5 | 触发 Curation 阻断 axios@1.7.2 | 20 分 |
| T6 | 修复并完成 Build #3 | 20 分 |
| **合计** | | **100 分** |

同分时，最后一个任务完成越早排名越高。

### 奖励
> 由讲师现场宣布 🎁

---

## 快速开始

### 第一步：在 GitHub Codespace 中打开

点击下方按钮，在云端一键启动开发环境（无需在本机安装任何工具）：

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/alexwang66/jfrog-workshop)

> ⏱️ Codespace 首次启动约需 1-2 分钟，请耐心等待。
>
> 💻 **如果无法使用 Codespace**，请参阅 [SETUP.md](./SETUP.md) 在本地机器上配置所需环境。

### 第二步：打开 AI 助理

Codespace 启动完成后，点击窗口**右侧**的 **GitHub Copilot Chat** 图标（💬）打开对话面板。

> 🤖 **如果 Copilot Chat 不可用**，可以直接阅读 [.github/copilot-instructions.md](.github/copilot-instructions.md)，其中包含所有任务的完整步骤和命令，按顺序执行即可。

### 第三步：开始 Workshop

在 Copilot Chat 对话框中输入：

```
我要开始 workshop，EVENT_ID 是 <讲师提供的ID>
```

AI 助理将引导你完成所有任务，包括用讲师提供的管理员账号登录 JFrog UI 生成个人 Token、注册昵称、执行每一步操作。

> 💡 **提示**：整个过程中，所有命令都由 AI 助理提供，你只需在终端中执行即可。
>
> 📊 **排行榜**：讲师会将终端排行榜投屏，每 30 秒实时刷新。

---

## 任务概览

以下是 6 个任务的简要说明（具体命令由 AI 助理在对话中提供）：

| 任务 | 说明 | 验证方式 |
|------|------|---------|
| **T1 注册昵称** | 选择一个独特昵称，脚本自动在 Artifactory 上为你创建专属的 npm 仓库组（local / remote / virtual） | Artifactory 中存在 `{昵称}-npm-virtual` 仓库 |
| **T2 首次安装** | 配置 JFrog CLI 指向你的 Artifactory 虚拟仓库，运行 `jf npm install` | `{昵称}-npm-remote` 仓库中有缓存的包 |
| **T3 发布 Build Info** | 将构建的完整依赖信息发布到 Artifactory，建立可追溯性 | Artifactory 中存在 Build `{昵称}-npm-sample #1` |
| **T4 创建安全策略** | 在 JFrog Curation 中创建针对你个人 Artifactory 仓库的 npm 风险包拦截策略，命名须包含你的昵称 | Curation Policy 列表中存在名称包含昵称的 Policy |
| **T5 触发阻断** | 在项目中引入 `axios@1.7.2`（模拟恶意版本），运行 `jf npm install`，观察 Curation 如何拦截 | Curation 审计日志中有昵称对应仓库拦截 `axios@1.7.2` 的记录 |
| **T6 修复问题** | 将 axios 替换为安全版本，重新运行 `jf npm install` 并发布 Build #3 | Artifactory 中存在 Build `{昵称}-npm-sample #3`，且依赖中 axios 版本不是 `1.7.2` |

---

## 主办者指南

如果你是讲师或活动组织者，请参阅：

👉 [ORGANIZER.md](./ORGANIZER.md)
