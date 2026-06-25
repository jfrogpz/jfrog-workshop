# 如何添加新的 Workshop 模块

> 🌐 [English version](./CONTRIBUTING-MODULE.md)

本文档说明如何为 JFrog Workshop 创建新的学习模块。每个模块是一个独立单元，包含自己的任务定义、验证逻辑、示例项目和 AI 指南。

---

## 模块目录结构

在 `modules/` 下创建以模块命名的目录（使用小写字母、数字和连字符）：

```
modules/
└── <模块名>/
    ├── tasks.json            # 任务定义（必须）
    ├── verify-tasks.sh       # 任务验证函数（必须）
    ├── create-repo.sh        # Artifactory 仓库初始化（必须）
    ├── install-tools.sh      # 工具安装/验证（必须）
    └── sample-project/       # 学员示例项目（必须）

.github/instructions/
└── <模块名>.instructions.md   # Copilot Chat AI 指南（必须）
```

AI 指南放在 `.github/instructions/`（而不是模块目录内），这样当学员在编辑器中打开 `modules/<模块名>/` 下的文件时，GitHub Copilot Chat 会自动加载该指南。

**命名规范**：模块名应描述技术类型和重点方向，例如 `npm-security`、`maven-basic`、`pypi-curation`。

---

## 第一步：定义任务 — `tasks.json`

模块中的每个任务必须有唯一 ID，格式为 `<模块名>-T<序号>`。

```json
[
  {
    "id": "maven-basic-T1",
    "name": "Register nickname and create personal Maven repositories",
    "name_cn": "注册昵称并创建个人 Maven 仓库",
    "points": 10,
    "hint": "Run: bash automation/register.sh <NICKNAME> [EVENT_ID]",
    "hint_cn": "运行：bash automation/register.sh <NICKNAME> [EVENT_ID]"
  },
  {
    "id": "maven-basic-T2",
    "name": "Complete first Maven build",
    "name_cn": "完成首次 Maven 构建",
    "points": 20,
    "hint": "cd modules/maven-basic/sample-project, configure settings.xml, then run: jf mvn package",
    "hint_cn": "进入 modules/maven-basic/sample-project，配置 settings.xml，然后运行：jf mvn package"
  }
]
```

**规则**：
- 任务 ID 必须在**所有模块中唯一**（使用模块名前缀可保证这一点）
- **第一个任务**始终在注册时自动标记为 `done`（代表注册步骤本身）
- `points` 分值灵活设置，无需固定总分
- `hint` 和 `hint_cn` 在 `check-and-update-progress.sh` 输出中显示，帮助遇到困难的学员

---

## 第二步：创建 Artifactory 仓库 — `create-repo.sh`

该脚本由 `register.sh` 调用，为学员创建本模块所需的 Artifactory 仓库。`$1` 为学员昵称。

```bash
#!/bin/bash
# <模块名> 模块：创建个人 Artifactory 仓库

set -eu

NICKNAME="${1:-}"
[ -n "$NICKNAME" ] || { echo "Usage: $0 <nickname>" >&2; exit 1; }
[ -n "${JFROG_URL:-}" ] && [ -n "${JFROG_TOKEN:-}" ] || {
  echo "❌ JFROG_URL and JFROG_TOKEN must be set" >&2; exit 1
}

JFROG_URL="${JFROG_URL%/}"
API="${JFROG_URL}/artifactory/api"

curl_jf() { curl -sf -H "Authorization: Bearer ${JFROG_TOKEN}" "$@"; }

create_repo() {
  local key="$1" body="$2"
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" "${API}/repositories/${key}" 2>/dev/null || echo "000")
  if [ "$s" = "200" ]; then
    echo "    Already exists, skipping / 已存在，跳过：${key}"; return 0
  fi
  curl_jf -X PUT "${API}/repositories/${key}" -H "Content-Type: application/json" -d "$body" >/dev/null
  echo "    ✅ Created / 创建成功：${key}"
}

# Maven 示例：创建 local、remote、virtual 三类仓库
create_repo "${NICKNAME}-maven-dev-local" \
  '{"rclass":"local","packageType":"maven","repoLayoutRef":"maven-2-default","xrayIndex":true}'

create_repo "${NICKNAME}-maven-org-remote" \
  '{"rclass":"remote","packageType":"maven","url":"https://repo.maven.apache.org/maven2","repoLayoutRef":"maven-2-default","xrayIndex":true}'

create_repo "${NICKNAME}-maven-dev-virtual" \
  "{\"rclass\":\"virtual\",\"packageType\":\"maven\",\"repoLayoutRef\":\"maven-2-default\",\"repositories\":[\"${NICKNAME}-maven-dev-local\",\"${NICKNAME}-maven-org-remote\"],\"defaultDeploymentRepo\":\"${NICKNAME}-maven-dev-local\"}"
```

---

## 第三步：编写验证函数 — `verify-tasks.sh`

每个任务需要一个对应的验证函数，命名规则：`verify_<任务ID中的连字符替换为下划线>`。

`check-and-update-progress.sh` 会动态调用：任务 ID `maven-basic-T2` → 函数 `verify_maven_basic_T2`。

```bash
#!/bin/bash
# <模块名> 模块：任务验证函数
# 调用方会预先设置：NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf()

verify_maven_basic_T1() {
  # 验证注册：检查 virtual 仓库是否存在
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-maven-dev-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_maven_basic_T2() {
  # 验证首次 Maven 构建：检查 remote 仓库是否有缓存的包
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-maven-org-remote" 2>/dev/null \
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

## 第四步：添加示例项目 — `sample-project/`

将学员的起始项目文件放在这里。要求：
- 必须是目标包类型的可运行项目
- 至少包含一个能演示 Workshop 安全场景的依赖
- 保持简洁——学员不需要理解项目代码本身

---

## 第五步：声明工具依赖 — `install-tools.sh`

该脚本由 `.devcontainer/post-create.sh` 在 Codespace 启动时调用。应检查每个模块所需工具是否存在，不存在则安装。

```bash
#!/bin/bash
# <模块名> 模块：验证或安装所需工具

set -e

# ── maven ─────────────────────────────────────────────────────────────────────
if command -v mvn >/dev/null 2>&1; then
  echo "  ✅ mvn $(mvn --version 2>&1 | head -1)"
else
  echo "  Installing Maven / 安装 Maven..."
  sudo apt-get update -qq && sudo apt-get install -y maven
  echo "  ✅ mvn $(mvn --version 2>&1 | head -1)"
fi

# ── java ──────────────────────────────────────────────────────────────────────
if command -v java >/dev/null 2>&1; then
  echo "  ✅ java $(java --version 2>&1 | head -1)"
else
  echo "  ❌ java not found after Maven install — check apt output above" >&2
  exit 1
fi
```

**规则**：
- 用 `command -v <工具>` 检查后再安装——避免重复安装基础镜像中已有的工具
- 失败时以非零退出码退出，让 `post-create.sh` 立即显示错误
- 输出简洁：工具存在时一行 `✅`，不存在时显示安装进度

GitHub Codespace 默认基础镜像（`mcr.microsoft.com/devcontainers/universal`）已内置许多常用工具（Node.js、Python、Java、Go 等）。请先检查，只有缺少时才安装。

---

## 第六步：编写 AI 指南 — `.github/instructions/<模块名>.instructions.md`

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
- 每个任务章节的标题使用完整任务 ID（如 `### maven-basic-T2`）
- 包含**模块概述**表格，列出任务 ID、描述、分值和验证标准
- 提供完整可复制的命令，用 `<NICKNAME>` 作为占位符
- 列出模块前置条件（如需要启用 Curation、配置 Xray），方便组织者提前准备

---

## 第七步：在赛事中注册模块

模块准备好后，在初始化赛事时加入该模块：

```bash
bash automation/setup-event.sh \
  "2026-07-beijing" \
  "JFrog Workshop Beijing" \
  --modules npm-security,maven-basic
```

或单独测试：

```bash
bash automation/setup-event.sh \
  "2026-07-test" \
  "Module Test" \
  --modules maven-basic
```

---

## 发布前检查清单

- [ ] `tasks.json` — 所有任务 ID 使用 `<模块名>-T<序号>` 格式
- [ ] `tasks.json` — 第一个任务代表注册步骤（注册时自动完成）
- [ ] `create-repo.sh` — 创建本模块任务所需的所有仓库
- [ ] `verify-tasks.sh` — 每个任务对应一个 `verify_*` 函数，命名正确
- [ ] `verify-tasks.sh` — 所有函数已在真实 JFrog 实例上测试通过
- [ ] `install-tools.sh` — 先检查再安装，失败时以非零退出码退出
- [ ] `install-tools.sh` — 已在全新 Codespace 中测试（非本地环境）
- [ ] `sample-project/` — 仓库配置完成后项目可正常运行
- [ ] `.github/instructions/<模块>.instructions.md` — `applyTo` 已正确设置
- [ ] `.github/instructions/<模块>.instructions.md` — 包含带验证标准的模块概述表格
- [ ] `.github/instructions/<模块>.instructions.md` — 所有命令使用 `<NICKNAME>` 占位符
- [ ] `.github/instructions/<模块>.instructions.md` — 前置条件部分列出所需 JFrog 功能
- [ ] 运行 `bash automation/setup-event.sh` — 新模块出现在可用列表中
- [ ] 运行 `bash automation/register.sh` — 仓库创建成功
- [ ] 运行 `bash automation/check-and-update-progress.sh` — 所有任务验证正常
