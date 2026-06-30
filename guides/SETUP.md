# 本地环境配置指南（不使用 Codespace）

> 🌐 [English version](./SETUP_EN.md)

本文档面向不使用 GitHub Codespace 的学员，说明如何在本地机器上配置完成 Workshop 所需的环境。

> 如果你使用 GitHub Codespace，可以跳过本文档——环境已自动配置好，直接打开 Copilot Chat 开始任务即可。

---

## 需要安装的工具

### 1. JFrog CLI

```bash
# macOS（Homebrew）
brew install jfrog-cli

# Linux / macOS（通用）
curl -fL https://install-cli.jfrog.io | sh
```

验证：
```bash
jf -v
```

### 2. 模块专属工具

每个模块需要不同的工具。阅读模块 `install-tools.sh` 顶部的注释，了解需要安装哪些工具：

```bash
cat modules/curation-npm/install-tools.sh
```

按照注释中的说明逐一安装。例如，`curation-npm` 模块需要 **Node.js（v18+）**：

```bash
# macOS（Homebrew）
brew install node

# Ubuntu / Debian
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

验证：
```bash
node -v
npm -v
```

### 3. 克隆仓库

```bash
git clone https://github.com/jfrogpz/jfrog-workshop.git
cd jfrog-workshop
```

---

## 设置环境变量

讲师会提供以下信息，在终端中设置好环境变量后，后续所有命令都依赖这两个变量：

```bash
export JFROG_URL="https://yourcompany.jfrog.io"   # 讲师提供
export JFROG_TOKEN="your-access-token"             # 登录 JFrog UI 后自行生成
```

获取 Token：用讲师提供的管理员账号登录 JFrog UI → 右上角头像 → **Edit Profile** → **Access Tokens** → **Generate Token**。

> 注意：每次打开新终端都需要重新设置环境变量。建议加入 `~/.bashrc` 或 `~/.zshrc` 以持久化。

---

## 没有 AI 助理时如何完成任务

Codespace 中内置了 GitHub Copilot Chat，会自动读取任务引导文件并为你提供逐步指引。

如果你没有 Copilot，可以直接阅读模块的 AI 指南。先确定你要学习的模块，然后打开对应文件：

```
.github/instructions/<模块名>.instructions.md
```

例如，`curation-npm` 模块：

**[.github/instructions/curation-npm.instructions.md](../.github/instructions/curation-npm.instructions.md)**

该文档包含全部任务的详细步骤、命令和成功标志，与 AI 引导的内容完全一致，按顺序阅读执行即可。

---

## 示例项目路径

Codespace 中项目路径为 `/workspaces/jfrog-workshop/`，本地克隆后对应你的克隆目录，例如 `~/jfrog-workshop/`。

文档和脚本中出现的 `/workspaces/jfrog-workshop/` 请替换为你的本地路径：

```bash
# Codespace 中
cd /workspaces/jfrog-workshop/modules/curation-npm/sample-project

# 本地替换为
cd ~/jfrog-workshop/modules/curation-npm/sample-project
```
