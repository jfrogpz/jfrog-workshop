# 主办者操作手册

> 🌐 [English version](./ORGANIZER.md)

本文档面向讲师和活动组织者，说明如何准备和运行 JFrog Workshop。

> 如果不举办竞赛活动，学员可直接自主学习，**不需要组织者做任何初始化操作**。本文档仅适用于需要排行榜的赛事场景。

---

## 前置要求

| 项目 | 要求 |
|------|------|
| JFrog 实例 | JFrog Cloud（SaaS），域名格式 `xxx.jfrog.io` |
| Admin Token | 具有创建 Artifactory 仓库、管理权限、读取 build-info 的 Access Token |
| 学员人数 | 无硬性限制，建议 ≤ 50 人（Codespace 并发） |

---

## 步骤一：打开 Codespace（主办者）

打开本 GitHub 代码仓库页面，点击 **Code → Codespaces → New codespace**，等待环境就绪。

---

## 步骤二：设置环境变量并初始化赛事

先在终端中设置环境变量（**本次 Session 只需设置一次**，后续所有脚本都会读取）：

```bash
export JFROG_TOKEN="your-admin-token"
export JFROG_URL="https://yourcompany.jfrog.io"
```

运行不带参数的命令可查看当前所有可用模块：

```bash
bash automation/setup-event.sh
```

然后运行初始化脚本，指定本场赛事要使用的学习模块：

```bash
bash automation/setup-event.sh \
  "2026-06-shanghai" \
  "JFrog Workshop Shanghai 2026" \
  --modules npm-security
```

如果需要同时包含多个模块，或在赛事进行中追加模块，用完整的模块列表重新运行脚本即可——脚本会用合并后的任务集覆盖 `config.json`。已有学员的完成记录不受影响，排行榜下次刷新时会自动出现新模块列。

```bash
bash automation/setup-event.sh \
  "2026-06-shanghai" \
  "JFrog Workshop Shanghai 2026" \
  --modules npm-security,npm-basic
```

脚本将：
- 验证所有指定模块在 `modules/` 目录中存在
- 在 Artifactory 中创建 `workshop-events` Generic 仓库（如不存在）
- 从各模块的 `tasks.json` 聚合任务列表，上传赛事配置 `config.json`
- 输出启动排行榜的完整命令

---

## 步骤三：启动排行榜

在终端中运行以下命令（**Workshop 期间保持运行，将此终端窗口投屏**）：

```bash
# JFROG_TOKEN 和 JFROG_URL 已在步骤二中设置，无需重复设置
bash automation/refresh-leaderboard.sh "2026-06-shanghai"
```

脚本每 30 秒自动：
- 读取所有学员上传的 `progress.json`
- 清屏并刷新终端排行榜

按 `Ctrl+C` 停止。

单模块赛事（`--modules npm-security`）排行榜效果示例：

```
==============================================================
  🏆  JFrog Workshop  |  Event ID / 赛事 ID：2026-06-shanghai
  🕐  Updated / 更新时间：2026-06-22 10:30:00  |  Max / 满分：100 pts
==============================================================

  ──  npm-security  max: 100 pts  ────────────────────────
  Rank Nickname / 昵称         T1  T2  T3  T4  T5  T6    Pts
  ------------------------------------------------------------
  🥇   alex                  ✅  ✅  ✅  ⬜  ⬜  ⬜   30pts
  🥈   mary-chen             ✅  ✅  ⬜  ⬜  ⬜  ⬜   20pts
  🥉   bob                   ✅  ⬜  ⬜  ⬜  ⬜  ⬜   10pts
  ------------------------------------------------------------

  ──  Summary / 汇总  ────────────────────────────────────
  Rank Nickname / 昵称                            Total
  ------------------------------------------------------------
  🥇   alex                                      30pts
  🥈   mary-chen                                 20pts
  🥉   bob                                       10pts
  ------------------------------------------------------------
  3 participants / 名学员参赛
==============================================================
```

多模块赛事（`--modules npm-security,npm-basic`），每个模块独立排名，最后汇总总分：

```
==============================================================
  🏆  JFrog Workshop  |  Event ID / 赛事 ID：2026-06-shanghai
  🕐  Updated / 更新时间：2026-06-22 10:30:00  |  Max / 满分：160 pts
==============================================================

  ──  npm-security  max: 100 pts  ────────────────────────
  Rank Nickname / 昵称         T1  T2  T3  T4  T5  T6    Pts
  ------------------------------------------------------------
  🥇   alex                  ✅  ✅  ✅  ⬜  ⬜  ⬜   30pts
  🥈   mary-chen             ✅  ✅  ⬜  ⬜  ⬜  ⬜   20pts
  ------------------------------------------------------------

  ──  npm-basic  max: 30 pts  ────────────────────────────
  Rank Nickname / 昵称         T1  T2    Pts
  -------------------------------------------
  🥇   mary-chen             ✅  ✅   30pts
  🥈   alex                  ✅  ⬜   10pts
  -------------------------------------------

  ──  Overall / 总排行  ──────────────────────────────────
  Rank Nickname / 昵称                            Total
  ------------------------------------------------------------
  🥇   mary-chen                                 50pts
  🥈   alex                                      40pts
  ------------------------------------------------------------
  2 participants / 名学员参赛
==============================================================
```

> **说明**：列标签显示任务 ID 的最后一段（如 `npm-security-T1` → `T1`）。每个模块区块按该模块得分独立排名。

---

## 步骤四：向学员提供以下信息

开始前，告知所有学员：

| 信息 | 值 |
|------|-----|
| JFROG_URL | `https://yourcompany.jfrog.io`（即 `$JFROG_URL` 的值） |
| 管理员账号 | JFrog 管理员用户名（学员用此账号登录 JFrog UI） |
| 管理员密码 | JFrog 管理员密码 |
| EVENT_ID | `2026-06-shanghai`（你设置的值） |
| 开始方式 | 打开 Codespace → 在右侧内嵌的 Copilot Chat 中输入"我要开始 workshop，EVENT_ID 是 xxx" |

> **说明**：所有学员共用同一个管理员账号登录 JFrog UI，登录后各自在 **Edit Profile → Access Tokens** 生成自己的 Token。各自的 Token 互相独立，不会冲突。Workshop 结束后建议修改管理员密码。

---

## 赛前飞行检查

在正式开始前确认以下事项：

1. **确认模块前置条件**：检查你选择的模块是否需要启用特定 JFrog 功能（如 Curation、Xray）。各模块的前置要求请参阅对应的 `.github/instructions/<module>.instructions.md` 文件
2. **提前走通全流程**：使用测试环境模拟学员完成所选模块的全部任务，确认每个任务的验证逻辑正常工作，避免 Workshop 当天出现意外

---

## 赛后清理

### 清理单个学员数据

```bash
# JFROG_TOKEN 和 JFROG_URL 已在步骤二中设置
bash automation/delete-repo.sh <nickname> all --event-id "2026-06-shanghai"
```

### 批量清理所有学员

```bash
# 列出所有已注册学员（需已设置 JFROG_TOKEN 和 JFROG_URL）
curl -s -H "Authorization: Bearer $JFROG_TOKEN" \
  "${JFROG_URL}/artifactory/api/storage/workshop-events/2026-06-shanghai/participants" \
  | python3 -c "import sys,json; [print(c['uri'].strip('/')) for c in json.load(sys.stdin).get('children',[])]"

# 对每个学员逐一运行 delete-repo.sh
```

### 删除整个赛事数据

在 Artifactory UI 中删除 `workshop-events/2026-06-shanghai/` 目录即可。

---

## 故障排查

| 问题 | 排查方法 |
|------|---------|
| 排行榜无学员显示 | 检查 Artifactory 中 `workshop-events/{event_id}/participants/` 目录是否有数据 |
| 学员任务长时间不更新 | 确认 `refresh-leaderboard.sh` 正在运行；检查 Admin Token 是否有效 |
| 模块特定功能不工作 | 参阅对应模块的 `.github/instructions/<module>.instructions.md` 中的 Troubleshooting 部分 |

---

## 赛事配置自定义

如需调整各任务分值，修改对应模块目录下的 `tasks.json`（如 `modules/npm-security/tasks.json`），然后重新运行初始化脚本即可覆盖 `config.json`：

```bash
bash automation/setup-event.sh "2026-06-shanghai" "JFrog Workshop Shanghai 2026" --modules npm-security
```

如需新增学习模块，请参阅 [CONTRIBUTING-MODULE.md](CONTRIBUTING-MODULE.md)。

---

## 架构说明

### 为什么使用 GitHub Codespace 作为学员环境

| 问题 | Codespace 的解法 |
|------|----------------|
| 学员环境各异（Windows/Mac/Linux） | 统一的云端 Linux 环境，开箱即用 |
| 需要预装各类构建工具和 JFrog CLI | `.devcontainer/post-create.sh` 自动扫描各模块的 `install-tools.sh` 并安装所需工具 |
| 示例项目需要克隆仓库 | Codespace 启动时自动 checkout，路径固定为 `/workspaces/jfrog-workshop/` |
| 需要 AI 引导降低上手门槛 | GitHub Copilot Chat 直接内嵌在 IDE 中，打开模块目录下的文件时自动加载对应模块的 AI 指引 |

---

### 积分与排行榜工作原理

**学员注册**：
- 学员运行 `register.sh`，脚本从赛事 `config.json` 读取活跃模块，创建所需资源，并写入初始 `progress.json`
- 注册成功后，脚本在学员本地写入 `~/.workshop-profile`，保存昵称、赛事 ID、JFrog 地址和 Token，后续脚本均从此文件读取，无需重复输入

**任务验证**：
- **验证发生在学员侧**：学员每完成一个任务后运行 `check-and-update-progress.sh`，脚本动态加载各模块的 `verify-tasks.sh`，按任务 ID 派发到对应的验证函数
- 验证通过的任务标记为 `done`，进度上传至 `workshop-events` 仓库供排行榜读取
- 已完成的任务不重复验证，只验证尚未完成的任务

任务 ID 格式为 `<模块名>-T<序号>`，如 `npm-security-T1`。各任务的验证逻辑详见对应模块的 `.github/instructions/<module>.instructions.md`。

**排行榜渲染**：
- 组织者运行 `refresh-leaderboard.sh`，脚本每 30 秒**只读取**所有学员上传的 `progress.json`，不做任何验证
- 积分只计算赛事 `config.json` 中定义的任务，自主学习阶段完成的其他模块任务不计入赛事积分
- 按总分降序、同分按最后任务完成时间升序排列
- 组织者将此终端窗口投屏，学员实时可见

> **注意**：排行榜反映的是学员最后一次运行 `check-and-update-progress.sh` 时上传的进度。学员完成任务后需主动运行脚本，进度才会更新。

---

### 为什么用 Artifactory 存数据

- **零额外依赖**：学员本来就要操作 Artifactory，不需要额外搭建数据库或 API 服务
- **REST API 完备**：上传、下载、列目录都有标准 API，bash + curl + python3 即可驱动
- **可视化调试**：组织者可以直接在 Artifactory UI 中查看或修改任何学员的 JSON 文件

```
Artifactory Generic 仓库：workshop-events
│
└── {event_id}/                        # 赛事目录，例如 2026-06-shanghai
    ├── config.json                    # 赛事配置（模块列表、任务分值、时间等）
    └── participants/
        └── {nickname}/                # 每位学员一个目录
            ├── profile.json           # 学员信息（昵称、注册时间）
            └── progress.json          # 学员进展（各任务状态和得分）
```
