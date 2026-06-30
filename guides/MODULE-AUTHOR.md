# JFrog Workshop — 模块开发指南

> 🌐 [English version](./MODULE-AUTHOR_EN.md)

本指南帮助你用 AI 开发新的 Workshop 模块。你负责描述需求和审查输出，AI 负责生成所有文件。

---

## 如何新增模块

### 第一步：向 AI 描述模块需求

在 Claude Code 或 Copilot Chat 中，描述你想做的模块。给出足够信息让 AI 做决策：

```
开发一个新的 Workshop 模块 <模块名>：
- 功能目标：让学员体验 <JFrog 产品/功能>
- 使用的包类型：npm / maven / docker / pypi
- 任务数量：5 个，总分 90 分
- 关键任务流程：<大致描述>
- 示例项目：需要包含 <特定依赖/场景>
```

AI 会依次生成所有必要文件，包括任务定义、验证脚本、示例项目、AI 指引、以及更新模块目录页数据。

### 第二步：审查关键文件

AI 生成后，重点检查：

- **tasks.json**：任务流程是否合理？分值是否体现难度梯度（T1 最低）？最后的 UI 探索任务是否标记了 `"verify": false`？
- **verify-tasks.sh**：每个验证函数的名称是否与任务 ID 精确对应（连字符→下划线）？验证逻辑是否真正反映"任务完成"而不仅是"仓库存在"？
- **sample-project**：示例项目能否直接运行？安全模块是否包含了合适的演示依赖？
- **instructions.md**：命令是否完整可复制？是否覆盖了常见故障排查？

### 第三步：告诉 AI 调整

直接说明问题，AI 会修改对应文件：

```
verify-tasks.sh 的 T3 验证不够准确，应该检查
/xray/api/v2/policies 接口中是否有名称包含 nickname 的策略
```

---

## 模块目录结构

```
modules/
└── <模块名>/
    ├── tasks.json            # 任务定义（必须）
    ├── verify-tasks.sh       # 任务验证函数（必须）
    ├── sample-project/       # 学员的起始项目（通常需要）
    ├── create-repo.sh        # 创建 Artifactory 仓库（通常需要）
    ├── install-tools.sh      # 工具检查/安装（必须）
    └── <其它脚本>/           # 可选，如 clear-cache.sh

.github/instructions/
├── <模块名>.instructions.md      # AI 指引（中文，必须）
└── <模块名>.instructions-en.md  # AI 指引（英文，可选）
```

各文件的作用与调用关系：

| 文件 | 作用 | 由谁调用 |
|------|------|---------|
| `tasks.json` | 任务列表：ID、名称、分值、提示文字 | `check-and-update-progress.sh`、目录页渲染 |
| `verify-tasks.sh` | 每个任务的 API 验证逻辑 | `check-and-update-progress.sh` 动态 source |
| `sample-project/` | 学员直接操作的示例代码 | 学员使用 |
| `create-repo.sh` | 一键创建学员专属 Artifactory 仓库 | 学员手动运行（T1 提示中给出） |
| `install-tools.sh` | 检查/安装必要工具 | Codespace 启动时由 `post-create.sh` 调用 |
| `<模块名>.instructions.md` | AI 任务步骤指引、命令、验证标准、故障排查 | Copilot Chat 自动加载；Claude Code 主动 cat |

参考现有模块的真实实现：[modules/](../modules/)

---

## 模块设计原则

### 命名规范

模块名通常遵循 `<产品线>-<生态系统>` 的格式，但这是建议而非强制。

以 `xray-npm` 为例：产品线是 `xray`（JFrog Xray 漏洞扫描），生态系统是 `npm`。类似地，`curation-docker` 是 Curation 产品 + Docker 生态，`ci-github-actions` 是 CI 集成 + GitHub Actions（无特定包生态）。

查看现有所有模块命名作为参考：[模块目录页](https://jfrogpz.github.io/jfrog-workshop/)

### 模块自包含，不依赖其他模块

每个模块从零开始运行，不假设学员完成过任何其他模块。即使步骤（如创建仓库）与其他模块重复，也要完整包含在本模块的 T1/T2 中。

原因：组织者可以将任意模块组合成一场活动，任意顺序分配给学员。

### 关于任务验证

每个任务（除了标记 `"verify": false` 的 UI 探索任务）都必须有对应的 API 验证方法。**设计任务时先想清楚：如何通过 REST API 判断学员完成了这个任务？** 如果验证方式想不清楚，任务本身的设计可能需要调整。

常用验证模式：

| 验证目标 | API |
|---------|-----|
| 仓库是否存在 | `GET /artifactory/api/repositories/{repo}` → 200 |
| 构建/安装是否运行过 | `GET /artifactory/api/storage/{repo}` → `children` 非空 |
| Build Info 是否发布 | `GET /artifactory/api/build/{name}/{number}` → 200 |
| Xray 策略/Watch 是否创建 | `GET /xray/api/v2/policies` 或 `/watches`，结果中匹配 nickname |
| Curation 策略是否创建 | `GET /xray/api/v1/curation/policies`，结果中匹配 nickname |

`"verify": false` 的任务（如"在 UI 中查看结果"）框架会自动放行，AI 指引仍会引导学员完成步骤，分数正常发放。

---

## AI 指引文件

`.github/instructions/<模块名>.instructions.md` 是 AI 助理引导学员完成任务的脚本，也是任务指导的唯一真实来源。

**创建新模块时，应参考现有模块的指引文件作为模板**，例如 [xray-npm.instructions.md](../.github/instructions/xray-npm.instructions.md)，了解结构和写法后告知 AI 按相同风格生成。

指引文件通过两种方式加载：

- **自动加载**（Copilot Chat）：文件开头的 `applyTo: "modules/<模块名>/**"` frontmatter，使学员在编辑器中打开模块目录下任意文件时自动注入
- **主动加载**（Claude Code）：学员选择模块时，Claude Code 执行 `cat .github/instructions/<模块名>.instructions.md` 读取内容

每个任务章节的标题必须包含完整任务 ID（如 `### xray-npm-T3`），AI 用此匹配学员当前进度。命令中使用 `$NICKNAME` 变量（来自 `~/.workshop-profile`）。

---

## 模块目录页面

[模块目录页](https://jfrogpz.github.io/jfrog-workshop/) 的数据来自 `docs/module-catalog.json`。开发者不需要手动维护这个文件——**每次模块开发完成后，AI 会自动更新它**，包括：

- 将 `status` 从 `coming-soon` 改为 `available`
- 将 `tasks.json` 中的任务列表同步到 `tasks` 数组
- 根据模块内容分析并填写 `tags`（scenario / role / ecosystem）

如果需要手动触发标签重新分析，在 Claude Code 中运行 `/update-tags`。

---

## 注意事项

**跨文件一致性**：任何概念（模块 ID、任务 ID、仓库名、脚本参数）一旦修改，必须覆盖它存在的所有文件，并在同一次提交中完成，避免中间状态不一致。

**模块状态**：`status` 字段只在 `module-catalog.json` 中维护，其他任何文件不重复记录。
