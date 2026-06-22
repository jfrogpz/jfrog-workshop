# 主办者操作手册

本文档面向讲师和活动组织者，说明如何准备和运行 JFrog Workshop。

---

## 前置要求

| 项目 | 要求 |
|------|------|
| JFrog 实例 | JFrog Cloud（SaaS），域名格式 `xxx.jfrog.io` |
| Admin Token | 具有创建仓库、管理权限、读取 build-info 的 Access Token |
| 学员人数 | 无硬性限制，建议 ≤ 50 人（Codespace 并发） |

### 提前准备

1. **确认 Curation 已启用**：登录 JFrog UI → Curation，确认功能已开启且有 npm 支持
2. **准备 axios@1.7.2 模拟恶意包**：在 Curation 中配置针对该版本的 Block 规则（或使用平台内置恶意包检测，确认 axios@1.7.2 会被阻断）
3. **获取 Admin Access Token**：User Profile → Access Tokens → Generate（不过期，或设置足够长的有效期）

---

## 步骤一：启动 Codespace（主办者本机）

打开仓库页面，点击 **Code → Codespaces → New codespace**，等待环境就绪。

或在本机直接运行脚本（需要已安装 `curl` 和 `python3`）。

---

## 步骤二：初始化赛事

运行 `setup-event.sh`，传入赛事信息：

```bash
bash automation/setup-event.sh \
  "2025-06-shanghai" \
  "JFrog Workshop Shanghai 2025" \
  "https://yourcompany.jfrog.io" \
  "$JFROG_ADMIN_TOKEN"
```

脚本将：
- 在 Artifactory 创建 `workshop-events` Generic 仓库（如不存在），并开启 `archiveBrowsingEnabled`
- 配置匿名读权限（排行榜页面 fetch 需要）
- 上传 `config.json`、空 `leaderboard.json` 和排行榜页面 `index.html`
- 输出排行榜地址，直接可投屏

> ⚠️ 如果匿名读权限配置失败（某些实例有限制），请手动在 UI 中设置：
> **Security → Permissions → New Permission** → 选择 `workshop-events` 仓库 → 为 Anonymous 用户授予 Read 权限

---

## 步骤三：启动排行榜刷新服务

在主办者的终端中持续运行（**Workshop 期间保持运行**）：

```bash
bash automation/refresh-leaderboard.sh \
  "2025-06-shanghai" \
  "https://yourcompany.jfrog.io" \
  "$JFROG_ADMIN_TOKEN"
```

脚本每 30 秒自动：
- 验证所有学员的任务完成状态
- 更新各学员的 `progress.json`
- 生成并上传新的 `leaderboard.json`

按 `Ctrl+C` 停止。

> 💡 建议在 `tmux` 或 `screen` 会话中运行，防止终端关闭导致中断。
> ```bash
> tmux new -s leaderboard
> bash automation/refresh-leaderboard.sh ...
> # Ctrl+B, D 挂起；tmux attach -t leaderboard 恢复
> ```

---

## 步骤四：将排行榜 URL 投屏

`setup-event.sh` 完成后会直接输出排行榜地址，格式为：

```
https://yourcompany.jfrog.io/artifactory/workshop-events/index.html?event=<EVENT_ID>
```

排行榜托管在 Artifactory 上，每 30 秒自动刷新，适合投屏展示。

---

## 步骤五：向学员提供以下信息

开始前，告知所有学员：

| 信息 | 值 |
|------|-----|
| EVENT_ID | `2025-06-shanghai`（你设置的值） |
| JFROG_URL | `https://yourcompany.jfrog.io` |
| 获取 Token 的方式 | JFrog UI → 右上角头像 → Edit Profile → Access Tokens → Generate |
| 排行榜地址 | `https://yourcompany.jfrog.io/artifactory/workshop-events/index.html?event=<EVENT_ID>` |
| 开始方式 | 打开 Codespace → Copilot Chat → 输入"我要开始 workshop" |

---

## 赛后清理

### 清理单个学员数据

```bash
bash automation/delete-repo.sh <nickname> all \
  --event-id "2025-06-shanghai" \
  --jfrog-url "https://yourcompany.jfrog.io" \
  --token "$JFROG_ADMIN_TOKEN"
```

### 批量清理所有学员

```bash
# 列出所有已注册学员
curl -s -H "Authorization: Bearer $JFROG_ADMIN_TOKEN" \
  "https://yourcompany.jfrog.io/artifactory/api/storage/workshop-events/2025-06-shanghai/participants" \
  | python3 -c "import sys,json; [print(c['uri'].strip('/')) for c in json.load(sys.stdin).get('children',[])]"

# 对每个学员运行 delete-repo.sh
```

### 删除整个赛事数据

在 Artifactory UI 中删除 `workshop-events/2025-06-shanghai/` 目录即可。

---

## 故障排查

| 问题 | 排查方法 |
|------|---------|
| 排行榜显示"加载失败" | 检查 `workshop-events` 仓库的匿名读权限；检查 `archiveBrowsingEnabled` 是否开启；检查 URL 参数是否正确 |
| 学员任务验证不更新 | 确认 `refresh-leaderboard.sh` 正在运行；检查 Admin Token 权限 |
| Curation 不阻断 axios@1.7.2 | 在 Curation UI 确认策略已激活，且应用于学员的 remote 仓库 |
| Codespace 启动失败 | 检查 `.devcontainer/devcontainer.json` 中镜像是否可访问 |
| T4 验证失败 | Curation Policy API 路径可能因版本而异，检查 `refresh-leaderboard.sh` 中的 API 路径 |

---

## 赛事配置自定义

编辑 `automation/setup-event.sh` 中的任务配置，或在上传 `config.json` 后直接在 Artifactory UI 中编辑文件，可以：
- 调整各任务的分值
- 添加或删除任务
- 修改赛事时长（`end_time` 字段影响排行榜倒计时）
