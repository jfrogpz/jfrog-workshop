# 更新模块 Catalog 标签

你正在帮助更新 `docs/module-catalog.json` 中的模块/资源标签。请严格遵守以下标准。

---

## 标签结构

每个条目有三个标签维度，均为数组：

```json
"tags": {
  "scenario": [...],
  "role":     [...],
  "ecosystem": [...]
}
```

---

## 允许值及判断标准

### scenario（使用场景）

| 值 | 含义 | 判断标准 |
|----|------|---------|
| `workshop` | 动手实验室，学员按步骤完成任务 | 模块有 tasks[] 且需要在 JFrog 平台上实际操作 |
| `poc` | 适合在 POC/演示场景中展示价值 | 模块涉及安全特性或高级功能，能直接说明产品价值；纯 artifactory-* 仓库配置不打此标签 |
| `onboarding` | 适合新用户入门 | 从零开始配置，任务难度低，无需先修知识 |
| `adoption` | 适合现有客户深化使用 | 模块聚焦扩展高级功能（Xray、Curation、JAS、CI/CD），假设客户已有基础使用经验 |
| `feature-demo` | 新功能/新特性的独立演示 | 模块专为展示某一新发布特性而创建，成熟后可追加其他标签 |

### role（适用角色）

| 值 | 含义 | 判断标准 |
|----|------|---------|
| `developer` | 开发者日常的构建/发布任务 | 主要操作是 build、publish、配置包管理器 |
| `security` | 安全扫描、策略、合规任务 | 核心任务是配置 Xray 策略、处理 CVE、审计依赖 |
| `devsecops` | 跨职能的流水线+安全集成 | CI/CD 集成、Build Info、跨团队协作视角 |
| `admin` | 平台配置、权限、仓库管理 | 主要操作是仓库创建、RBAC、平台级配置 |

### ecosystem（技术生态）

| 值 | 适用条件 |
|----|---------|
| `npm` | 涉及 npm / Node.js 依赖管理 |
| `maven` | 涉及 Maven / Java 依赖管理 |
| `docker` | 涉及 Docker 镜像构建或容器仓库 |
| `python` | 涉及 PyPI / pip 依赖管理 |
| `helm` | 涉及 Helm Chart 仓库 |

> **注意**：如果模块/资源不绑定特定包生态系统（例如 xray-policies、access-management、通用概览文档），`ecosystem` 应为 `[]`。

---

## 操作规范

**读取上下文**：分析以下内容来判断标签（按优先级）：
1. `.github/instructions/<id>.instructions.md` — 任务详情最权威
2. `modules/<id>/tasks.json` — 任务 ID 和名称
3. `docs/module-catalog.json` 中的 `desc_en` / `desc_zh`

**coming-soon 模块**：只有 `desc_en`/`desc_zh`，没有 instructions 文件，根据描述判断即可。

**多值原则**：各维度可同时选多个值，但不要过度标记。`developer` + `security` 都应该时才同时选，不是"这个角色可能也会用"就加。

**一致性检查**：同类模块（如 artifactory-npm 和 maven-basic）的标签结构应保持相似，避免同类型模块标签差异过大。

---

## 输出格式

逐模块列出，格式如下：

```
── artifactory-npm
  scenario     [onboarding, poc, workshop]  →  [onboarding, poc, workshop]  （无变化）
  role         [developer]                  →  [developer, devsecops]       ★
  ecosystem    [npm]                        →  [npm]                        （无变化）
```

有变化的行末尾标 `★`，无变化注明"无变化"。

列出所有拟变更后，询问是否整批确认，还是逐个确认，再写入文件。

---

## 注意事项（经验总结）

- `artifactory-*` 模块不打 `poc` 标签——纯仓库配置无法打动决策者，POC 需要安全特性
- `jas-*` 和 `curation-ai` 初期只打 `feature-demo`，不打 `workshop`——功能成熟后再追加
- `ci-*` 和 `access-management` 的 ecosystem 为 `[]`——它们跨生态系统，不绑定特定包管理器
- `adoption` 和 `onboarding` 的区别：onboarding 是新用户从零配置，adoption 是现有用户扩展高级功能
- 外部资源（type: resource）暂时已从 catalog 中移除，等人工验证链接后再添加
