# JFrog 软件供应链安全 Workshop

> 🌐 [English version](./README.md)

本 Workshop 有三个特点：

- **开箱即用**：基于 GitHub Codespace，无需在本机安装任何工具，点击即可进入统一的云端开发环境
- **AI 助理引导**：内置 GitHub Copilot Chat，全程由 AI 助理提供操作指引，无需提前了解 JFrog 工具链
- **竞赛制，有乐趣**：完成任务实时得分，讲师投屏显示排行榜

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

## 本次 Workshop

### 目标
通过动手实践，体验从"引入恶意依赖"到"检测 → 阻断 → 修复"的完整供应链安全闭环。

### 时长
每个模块约 60 分钟

### 竞赛规则

任务以**模块**为单位组织（如 `npm-security`、`maven-basic`），每个模块有独立的任务列表和分值。讲师在创建赛事时指定本场活跃的模块。

- 完成活跃模块中的任务即可得分
- 同分时，最后一个任务完成越早排名越高
- 任务详情和操作命令由 AI 助理在对话中提供

### 奖励
> 由讲师现场宣布 🎁

---

## 快速开始

### 第一步：在 GitHub Codespace 中打开

点击下方按钮，在云端一键启动开发环境（无需在本机安装任何工具）：

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/jfrogpz/jfrog-workshop)

> ⏱️ Codespace 首次启动约需 1-2 分钟，请耐心等待。
>
> 🆓 GitHub 个人账号每月可免费使用 60 小时 Codespace，本 Workshop 约占用 1 小时。
>
> 💻 **如果无法使用 Codespace**，请参阅 [SETUP_CN.md](./docs/SETUP_CN.md) 在本地机器上配置所需环境。

### 第二步：打开 AI 助理

Codespace 启动完成后，窗口**右侧**已内嵌 **GitHub Copilot Chat** 对话面板，可直接输入消息。

> 🤖 **如果 Copilot Chat 不可用**，直接阅读对应模块的指令文件，例如 [.github/instructions/npm-security.instructions.md](.github/instructions/npm-security.instructions.md)，其中包含全部任务的详细步骤和命令。

### 第三步：开始 Workshop

在 Copilot Chat 对话框中输入：

```
# 自主学习模式（无需讲师，无需 EVENT_ID）
我要自主学习

# 赛事模式（有讲师组织）
我要开始 workshop，EVENT_ID 是 <讲师提供的ID>

# 中途切换模块
我想切换到 maven-basic 模块
```

AI 助理将：
1. 询问你想学习哪个模块（如尚未注册）
2. 引导你登录 JFrog UI 并生成个人 Access Token
3. 逐步引导你完成每一个任务

> 💡 **提示**：所有命令都由 AI 助理提供，你只需在终端中执行即可。
>
> 📊 **排行榜**（仅赛事模式）：讲师会将终端排行榜投屏，每 30 秒实时刷新。

---

## 主办者指南

如果你是讲师或活动组织者，请参阅：

👉 [ORGANIZER_CN.md](./docs/ORGANIZER_CN.md)
