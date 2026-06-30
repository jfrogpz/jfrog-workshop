---
applyTo: "modules/xray-docker/**"
---

# xray-docker 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **xray-docker** 模块。本模块聚焦于容器镜像安全扫描：通过 Artifactory 推送 Docker 镜像并发布 Build Info，创建 Xray 安全策略和 Watch，对镜像执行 CVE 扫描并查看层级漏洞分析。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块目标

使用 JFrog Xray 对容器镜像进行安全扫描：将 Docker 镜像推送至 Artifactory，发布 Build Info，配置安全策略与 Watch，扫描镜像并在 UI 中查看 CVE 详情与镜像层级漏洞溯源。

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| xray-docker-T1 | 在 Artifactory 中创建个人 Docker 仓库 | 10 | `{nickname}-docker-xray-virtual` 仓库存在 |
| xray-docker-T2 | 通过 Artifactory 构建并推送 Docker 镜像 | 20 | `{nickname}-docker-xray-local` 中有镜像 |
| xray-docker-T3 | 发布 Docker Build Info 到 Artifactory | 20 | `{nickname}-xray-docker-build/1` Build Info 存在 |
| xray-docker-T4 | 创建 Xray 安全策略和 Watch | 20 | 策略和 Watch 名称均包含昵称 |
| xray-docker-T5 | 查看容器镜像 CVE 扫描结果 | 20 | 手动验证（UI 探索）|
| **总计** | | **90** | |

**前置条件**：JFrog 实例已启用 Xray；本地已安装 Docker；JFrog 实例域名可用于 Docker 推送。

---

## 任务详情

### xray-docker-T1 — 在 Artifactory 中创建个人 Docker 仓库（10 分）

**目标**：创建三个启用 Xray 索引的 Docker 仓库（local / remote / virtual）。

**步骤**：

确认 profile 已加载：
```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
```

运行：
```bash
bash modules/xray-docker/create-repo.sh $NICKNAME
```

预期输出：
```
Creating Artifactory repositories for <nickname> (xray-docker)...
    ✅ Created: <nickname>-docker-xray-local
    ✅ Created: <nickname>-docker-xray-remote
    ✅ Created: <nickname>-docker-xray-virtual
✅ Repositories ready for <nickname>
```

---

### xray-docker-T2 — 通过 Artifactory 构建并推送 Docker 镜像（20 分）

**目标**：构建示例 Docker 镜像并通过 JFrog CLI 推送至 Artifactory，触发 Xray 索引。

**步骤**：

1. 配置 JFrog CLI（如已配置可跳过）：
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

2. 登录 Artifactory Docker 仓库：
   ```bash
   docker login ${JFROG_URL#https://} -u $NICKNAME -p $JFROG_TOKEN
   ```
   > 注：Docker login 使用域名不含 `https://`。

3. 进入示例项目并构建镜像：
   ```bash
   cd modules/xray-docker/sample-project
   DOCKER_REGISTRY="${JFROG_URL#https://}/docker"
   docker build -t ${DOCKER_REGISTRY}/${NICKNAME}-docker-xray-local/xray-demo:1.0 .
   ```

4. 通过 JFrog CLI 推送（带构建信息）：
   ```bash
   jf docker push ${DOCKER_REGISTRY}/${NICKNAME}-docker-xray-local/xray-demo:1.0 \
     --build-name=${NICKNAME}-xray-docker-build \
     --build-number=1
   ```

**成功标志**：JFrog UI → Artifactory → `{nickname}-docker-xray-local` 中可见 `xray-demo` 镜像。

**知识点**：`jf docker push` 在推送同时收集镜像层信息写入 Build Info，使 Xray 能将漏洞与具体的构建关联起来。

---

### xray-docker-T3 — 发布 Docker Build Info（20 分）

**目标**：将构建元数据发布至 Artifactory，为 Xray 扫描提供完整上下文。

**步骤**：

```bash
jf rt build-collect-env ${NICKNAME}-xray-docker-build 1
jf rt build-publish ${NICKNAME}-xray-docker-build 1
```

在 Artifactory UI 中验证：**Artifactory → Builds → `{nickname}-xray-docker-build`**

---

### xray-docker-T4 — 创建 Xray 安全策略和 Watch（20 分）

**目标**：创建 Security 策略定义 CVE 阈值，再创建 Watch 将 Docker 仓库与策略关联。

**创建策略**：

1. JFrog UI → Xray → Policies → **New Policy**
2. 填写：
   - **Name**：`{NICKNAME}-docker-policy`（名称必须包含昵称）
   - **Type**：Security
3. 添加规则：Min Severity = High，可选 Block download
4. 保存

**创建 Watch**：

1. JFrog UI → Xray → Watches → **New Watch**
2. 填写：
   - **Name**：`{NICKNAME}-docker-watch`（名称必须包含昵称）
3. Resources 中添加 `{NICKNAME}-docker-xray-local` 和 `{NICKNAME}-docker-xray-remote`
4. Assigned Policies 中添加 `{NICKNAME}-docker-policy`
5. 保存

**成功标志**：策略和 Watch 均在列表中可见，名称包含你的昵称。

---

### xray-docker-T5 — 查看容器镜像 CVE 扫描结果（20 分）

**目标**：在 JFrog UI 中探索容器镜像的 CVE 报告，理解镜像层级漏洞溯源。

**步骤**：

1. JFrog UI → Xray → Scans List → 找到 `{NICKNAME}-xray-docker-build`
2. 查看：
   - **Violations**：触发策略的 CVE
   - **CVE 详情**：CVSS 评分、受影响包、修复版本
   - **镜像层分析**：哪一层引入了漏洞（base image vs 应用层）

也可以手动触发扫描：
```bash
jf rt build-scan ${NICKNAME}-xray-docker-build 1
```

**本任务为手动验证，探索完 UI 后直接运行进度检查即可得分。**

**知识点**：Xray 可以区分漏洞来自 base image（python:3.9-slim）还是应用依赖（requirements.txt），帮助判断修复责任归属。

---

## 故障排查

**Docker login 失败**：确认域名不含 `https://`；确认 JFROG_TOKEN 有效且有读写权限。

**docker build 失败**：确认已进入 `modules/xray-docker/sample-project` 目录；确认 Docker daemon 正在运行。

**`jf docker push` 报 404**：确认 `{nickname}-docker-xray-local` 仓库已创建；确认镜像 tag 中的仓库路径正确。

**Xray 扫描结果为空**：等待 1-3 分钟让 Xray 完成索引；确认仓库创建时 `xrayIndex: true` 已设置。

**看不到 Xray 菜单**：确认 JFrog 实例已激活 Xray 许可证；联系讲师。
