# 主办者操作手册

本文档面向讲师和活动组织者，说明如何准备和运行 JFrog Workshop。

---

## 前置要求

| 项目 | 要求 |
|------|------|
| JFrog 实例 | JFrog Cloud（SaaS），域名格式 `xxx.jfrog.io` |
| Admin Token | 具有创建 Artifactory 仓库、管理权限、读取 build-info 的 Access Token |
| 学员人数 | 无硬性限制，建议 ≤ 50 人（Codespace 并发） |

### 提前准备

1. **确认 Curation 已启用**：登录 JFrog UI → Curation，确认功能已开启且支持 npm
2. **确认 axios@1.7.2 会被 Curation 识别为风险包**：在 JFrog UI → Curation 中搜索 axios@1.7.2，确认该版本有恶意标记（不需要提前创建 Policy，学员会在 T4 自己创建）
3. **获取 Admin Access Token**：JFrog UI → 右上角头像 → Edit Profile → Access Tokens → Generate（建议有效期不短于 workshop 时长）

---

## 步骤一：打开 Codespace（主办者）

打开本 GitHub 代码仓库页面，点击 **Code → Codespaces → New codespace**，等待环境就绪。

也可在本机直接运行脚本（需要已安装 `curl` 和 `python3`）。

---

## 步骤二：初始化赛事

运行 `setup-event.sh`，传入赛事信息：

```bash
export JFROG_TOKEN="your-admin-token"

bash automation/setup-event.sh \
  "2026-06-shanghai" \
  "JFrog Workshop Shanghai 2026" \
  "https://yourcompany.jfrog.io"
```

脚本将：
- 在 Artifactory 中创建 `workshop-events` Generic 仓库（如不存在）
- 上传赛事配置 `config.json`
- 输出启动排行榜的完整命令

---

## 步骤三：启动排行榜

在终端中运行以下命令（**Workshop 期间保持运行，将此终端窗口投屏**）：

```bash
# JFROG_TOKEN 已在步骤二中设置，无需重复设置
bash automation/refresh-leaderboard.sh \
  "2026-06-shanghai" \
  "https://yourcompany.jfrog.io"
```

脚本每 30 秒自动：
- 调用 Artifactory API 验证所有学员的任务完成状态
- 更新各学员在 Artifactory 中的 `progress.json`
- 清屏并刷新终端排行榜

按 `Ctrl+C` 停止。排行榜效果示例：

```
========================================================================
  🏆  JFrog Workshop 排行榜   赛事：2026-06-shanghai
  🕐  更新时间：2026-06-22 10:30:00
========================================================================
  排名  昵称                    T1  T2  T3  T4  T5  T6    总分
------------------------------------------------------------------------
  🥇   alex                   ✅  ✅  ✅  ⬜  ⬜  ⬜    50分
  🥈   mary-chen              ✅  ✅  ⬜  ⬜  ⬜  ⬜    30分
  🥉   bob                    ✅  ⬜  ⬜  ⬜  ⬜  ⬜    10分
------------------------------------------------------------------------
  共 3 名学员参赛
========================================================================
```

---

## 步骤四：向学员提供以下信息

开始前，告知所有学员：

| 信息 | 值 |
|------|-----|
| EVENT_ID | `2026-06-shanghai`（你设置的值） |
| JFROG_URL | `https://yourcompany.jfrog.io` |
| 获取个人 Token 的方式 | JFrog UI → 右上角头像 → Edit Profile → Access Tokens → Generate |
| 开始方式 | 打开 Codespace → 点击右侧 Copilot Chat → 输入"我要开始 workshop，EVENT_ID 是 xxx" |

---

## 赛后清理

### 清理单个学员数据

```bash
bash automation/delete-repo.sh <nickname> all \
  --event-id "2026-06-shanghai" \
  --jfrog-url "https://yourcompany.jfrog.io" \
  --token "$JFROG_TOKEN"
```

### 批量清理所有学员

```bash
# 列出所有已注册学员
curl -s -H "Authorization: Bearer $JFROG_TOKEN" \
  "https://yourcompany.jfrog.io/artifactory/api/storage/workshop-events/2026-06-shanghai/participants" \
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
| Curation 不阻断 axios@1.7.2 | 确认学员 Curation Policy 已激活，且 Apply to 选择了正确的 Artifactory 仓库（remote 仓库，不是 virtual） |
| Codespace 启动后缺少工具 | 执行 `Codespaces: Rebuild Container` 重建环境 |
| T4 验证始终失败 | Curation Policy API 路径可能因版本而异，检查 `refresh-leaderboard.sh` 中的 API 路径 |

---

## 赛事配置自定义

在 Artifactory UI 中直接编辑 `workshop-events/{event_id}/config.json` 可以：
- 调整各任务的分值
- 修改赛事结束时间
