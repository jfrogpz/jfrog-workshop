<div align="center">

<img src="./docs/banner.svg" alt="JFrog Workshop Banner" width="100%"/>

<br/>

[![STATUS](https://img.shields.io/badge/STATUS-LIVE-FCE138?style=flat-square&labelColor=0D0221)](https://jfrogpz.github.io/jfrog-workshop/)
[![MODULES](https://img.shields.io/badge/MODULES-13-00D4FF?style=flat-square&labelColor=0D0221)](https://jfrogpz.github.io/jfrog-workshop/)
[![ECOSYSTEM](https://img.shields.io/badge/ECOSYSTEM-5-FF2D6B?style=flat-square&labelColor=0D0221)](https://jfrogpz.github.io/jfrog-workshop/)
[![LANGUAGE](https://img.shields.io/badge/LANGUAGE-ZH%C2%B7EN-9B59B6?style=flat-square&labelColor=0D0221)](./README_EN.md)
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-444444?style=flat-square&labelColor=0D0221)](./LICENSE)

**[English version →](./README_EN.md)**

</div>

---

本 Workshop 有以下特点：

- **开箱即用**：基于 GitHub Codespace，无需在本机安装任何工具，点击即可进入统一的云端开发环境
- **AI 助理引导**：支持 GitHub Copilot Chat 和 Claude Code，全程由 AI 助理提供操作指引，无需提前了解 JFrog 工具链
- **自主学习模式**：无需讲师组织，随时开始，按自己节奏完成任务，AI 助理全程陪伴
- **竞赛模式**：有乐趣，完成任务实时得分，讲师投屏显示排行榜
- **自由扩展**：指引 AI 一键扩展学习模块，灵活定制任务，自动验证成功条件

---

## `// WORKSHOP_INFO`

### 模块目录

👉 **[查看所有学习模块和资源](https://jfrogpz.github.io/jfrog-workshop/)**

可在目录页按场景、角色、生态系统筛选，查看每个模块的任务列表和时长。

### 时长
每个模块约 10 分钟

### 竞赛模式规则

任务以**模块**为单位组织（如 `npm-basic`、`npm-security`），每个模块有独立的任务列表和分值。讲师在创建赛事时指定本场活跃的模块。

- 完成活跃模块中的任务即可得分
- 同分时，最后一个任务完成越早排名越高
- 任务详情和操作命令由 AI 助理在对话中提供

### 奖励
> 由讲师现场宣布 🎁

---

## `// QUICK_START`

### 第一步：在 GitHub Codespace 中打开

点击下方按钮，在云端一键启动开发环境（无需在本机安装任何工具）：

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/jfrogpz/jfrog-workshop)

> ⏱️ Codespace 首次启动约需 1-2 分钟，请耐心等待。
>
> 💻 **如果无法使用 Codespace**，请参阅 [SETUP.md](./guides/SETUP.md) 在本地机器上配置所需环境。

### 第二步：打开 AI 助理

本 Workshop 支持两种 AI 助理，选择你已有的即可：

**方式一：GitHub Copilot Chat（推荐，Codespace 内置）**

Codespace 启动完成后，窗口**右侧**已内嵌 **GitHub Copilot Chat** 对话面板，可直接输入消息。

**方式二：Claude Code（本地环境）**

在本地 clone 仓库后，用 [Claude Code](https://claude.ai/code) 打开项目目录。`CLAUDE.md` 会自动加载，Claude 将作为你的 Workshop 助理，引导流程与 Copilot Chat 完全一致。

> 🤖 **如果两种 AI 助理都不可用**，直接阅读对应模块的指令文件：`.github/instructions/<module>.instructions.md`，其中包含全部任务的详细步骤和命令。

### 第三步：开始 Workshop

在 AI 助理对话框中输入：

```
# 自主学习模式（无需讲师，无需 EVENT_ID）
我要自主学习

# 赛事模式（有讲师组织）
我要开始 workshop，EVENT_ID 是 <讲师提供的ID>

# 中途切换模块
我想切换到 npm-security 模块

# 中途切换模式（会保留当前学习进度）
我想切换到比赛模式
```

AI 助理将：
1. 引导你登录 JFrog UI 并生成个人 Access Token
2. 询问你想学习哪个模块
3. 逐步引导你完成每一个任务（可以为你检查学习进度，讲解知识点，分析遇到的问题）

> 💡 **提示**：所有命令都由 AI 助理提供，你只需在终端中执行即可。
>
> 📊 **排行榜**（仅赛事模式）：讲师会将终端排行榜投屏，每 30 秒实时刷新。

---

## `// ORGANIZER_GUIDE`

如果你是讲师或活动组织者，请参阅：

👉 [ORGANIZER.md](./guides/ORGANIZER.md)

如需新增 Workshop 学习模块，请参阅：

👉 [MODULE-AUTHOR.md](./guides/MODULE-AUTHOR.md)
