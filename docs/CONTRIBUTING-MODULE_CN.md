# 如何添加新的 Workshop 模块

> 🌐 [English version](./CONTRIBUTING-MODULE.md)

本文档旨在配合 AI 助理（如 GitHub Copilot Chat）使用，帮助你开发新的 Workshop 模块——将本文档分享给 AI，描述你想构建的模块，即可开始协作。

本文档说明如何为 JFrog Workshop 创建新的学习模块。每个模块是一个独立单元，包含自己的任务定义、验证逻辑、示例项目和 AI 指南。

---

## 模块目录结构

在 `modules/` 下创建以模块命名的目录（使用小写字母、数字和连字符）：

```
modules/
└── <模块名>/
    ├── tasks.json            # 任务定义（必须）
    ├── verify-tasks.sh       # 任务验证函数（必须）
    ├── create-repo.sh        # Artifactory 仓库初始化（可选）
    ├── install-tools.sh      # 工具安装/验证（必须）
    └── sample-project/       # 学员示例项目（必须）

.github/instructions/
├── <模块名>.instructions.md      # Copilot Chat AI 指南（必须）
└── <模块名>.instructions-cn.md  # 中文阅读指南，供没有 AI 助理的学员使用（可选）
```

AI 指南放在 `.github/instructions/`，通过两种方式加载：
- **自动加载**：`applyTo: "modules/<模块名>/**"` frontmatter 使 Copilot Chat 在学员编辑器中打开 `modules/<模块名>/` 下任意文件时自动加载
- **主动加载**：`copilot-instructions.md` 指示 AI 在学员选择模块时执行 `cat .github/instructions/<模块名>.instructions.md`——即使学员没有在编辑器中打开文件也能生效

**命名规范**：模块名应描述技术类型和重点方向，例如 `npm-security`、`npm-basic`、`pypi-curation`。

---

## 第一步：定义任务 — `tasks.json`

模块中的每个任务必须有唯一 ID，格式为 `<模块名>-T<序号>`。

```json
[
  {
    "id": "npm-basic-T1",
    "name": "Create personal npm repositories",
    "name_cn": "创建个人 npm 仓库",
    "points": 10,
    "hint": "Run: bash modules/npm-basic/create-repo.sh <NICKNAME>",
    "hint_cn": "运行：bash modules/npm-basic/create-repo.sh <NICKNAME>"
  },
  {
    "id": "npm-basic-T2",
    "name": "Complete first npm publish",
    "name_cn": "完成首次 npm 发布",
    "points": 20,
    "hint": "cd modules/npm-basic/sample-project, configure .npmrc, then run: jf npm publish",
    "hint_cn": "进入 modules/npm-basic/sample-project，配置 .npmrc，然后运行：jf npm publish"
  }
]
```

**规则**：
- 任务 ID 必须在**所有模块中唯一**（使用模块名前缀可保证这一点）
- **第一个任务**通常是**创建仓库**任务——如果是，在 `create-repo.sh` 中将其标记为 `done`，或由 `register.sh` 设置初始状态
- `points` 分值灵活设置，无需固定总分
- `hint` 和 `hint_cn` 在 `check-and-update-progress.sh` 输出中显示，帮助遇到困难的学员

---

## 创建 Artifactory 仓库 — `create-repo.sh`（可选）

如果模块需要 Artifactory 仓库，请创建 `create-repo.sh`。可参考 `modules/npm-security/create-repo.sh` 作为示例。

---

## 第二步：编写验证函数 — `verify-tasks.sh`

每个任务需要一个对应的验证函数，命名规则：`verify_<任务ID中的连字符替换为下划线>`。

`check-and-update-progress.sh` 会动态调用：任务 ID `npm-basic-T2` → 函数 `verify_npm_basic_T2`。

```bash
#!/bin/bash
# <模块名> 模块：任务验证函数
# 调用方会预先设置：NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf()

verify_npm_basic_T1() {
  # 验证仓库创建：检查 npm virtual 仓库是否存在
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-npm-dev-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_npm_basic_T2() {
  # 验证首次 npm 发布：检查 remote 缓存仓库是否有内容
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-npm-remote" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}
```

**规则**：
- 函数名必须与任务 ID 完全对应（连字符→下划线）
- 每个函数返回 `0` 表示通过，非零表示未通过
- 函数可以使用 `NICKNAME`、`JFROG_URL`、`JFROG_TOKEN`、`API`、`curl_jf` — 这些由 `check-and-update-progress.sh` 在 source 此文件前设置好
- 各函数保持独立，不依赖其他验证函数的状态

---

## 第三步：添加示例项目 — `sample-project/`

将学员的起始项目文件放在这里。要求：
- 必须是目标包类型的可运行项目
- 至少包含一个能演示 Workshop 安全场景的依赖
- 保持简洁——学员不需要理解项目代码本身

---

## 第四步：声明工具依赖 — `install-tools.sh`

该脚本由 `.devcontainer/post-create.sh` 在 Codespace 启动时调用。可参考 `modules/npm-security/install-tools.sh` 作为示例。脚本应检查所需工具是否存在，不存在则安装，失败时以非零退出码退出。

---

## 第五步：编写 AI 指南 — `.github/instructions/<模块名>.instructions.md`

当学员在编辑器中打开 `modules/<模块名>/` 下的任何文件时，GitHub Copilot Chat 会自动加载此文件。它是任务指导的唯一真实来源——在此包含模块概述、任务步骤、验证标准和故障排查提示。

```markdown
---
applyTo: "modules/<模块名>/**"
---

# <模块名> 模块 — AI 助理指南

你正在引导学员完成 **<模块名>** 模块...
不要跟随其他模块的指令。

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| <模块名>-T1 | ... | 10 | ... |
| <模块名>-T2 | ... | 20 | ... |

**前置条件**：列出需要提前在 JFrog 中启用的功能。

## 任务详情

### <模块名>-T1 — ... (N 分)

**目标**：...
**步骤**：...
**成功标志**：...
**知识点**：...

...

## 故障排查

...
```

**规则**：
- `applyTo` 必须精确匹配 `"modules/<模块名>/**"`
- 每个任务章节的标题使用完整任务 ID（如 `### npm-basic-T2`）
- 包含**模块概述**表格，列出任务 ID、描述、分值和验证标准
- 提供完整可复制的命令，用 `<NICKNAME>` 作为占位符
- 列出模块前置条件（如需要启用 Curation、配置 Xray），方便组织者提前准备

你还可以创建可选的 `<模块名>.instructions-cn.md` 作为中文阅读指南，供没有 Copilot 的学员使用。该文件**不需要** `applyTo` frontmatter——它仅供学员手动阅读。

---

## 第六步：在赛事中注册模块

模块准备好后，在初始化赛事时加入该模块：

```bash
bash automation/setup-event.sh \
  "2026-07-beijing" \
  "JFrog Workshop Beijing" \
  --modules npm-security,npm-basic
```

或单独测试：

```bash
bash automation/setup-event.sh \
  "2026-07-test" \
  "Module Test" \
  --modules npm-basic
```
