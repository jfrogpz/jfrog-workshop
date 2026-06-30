---
applyTo: "modules/artifactory-docker/**"
---

# artifactory-docker 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **artifactory-docker** 模块。本模块聚焦于 Docker 制品代理：在 Artifactory 中建立个人 Docker 仓库组，通过 Artifactory 拉取镜像，构建并推送自定义镜像，发布 Build Info。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块目标

以 Artifactory 作为 Docker 镜像的统一代理和存储中心：所有拉取流量经过 Artifactory 缓存，所有自定义镜像推送至个人本地仓库，配合 Build Info 实现完整制品追溯。

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| artifactory-docker-T1 | 在 Artifactory 中创建个人 Docker 仓库 | 10 | `{nickname}-docker-virtual` 仓库存在 |
| artifactory-docker-T2 | 通过 Artifactory 拉取 Docker 镜像 | 20 | `{nickname}-docker-remote-cache` 中有缓存内容 |
| artifactory-docker-T3 | 构建并推送 Docker 镜像到 Artifactory | 20 | `{nickname}-docker-local` 中有镜像 |
| artifactory-docker-T4 | 发布 Docker Build Info 到 Artifactory | 20 | `{nickname}-docker-build` Build Info 存在 |
| **总计** | | **70** | |

**前置条件**：已安装 Docker Engine 或 Docker Desktop，JFrog Artifactory 实例支持 Docker 包类型。

---

## 任务详情

### artifactory-docker-T1 — 在 Artifactory 中创建个人 Docker 仓库（10 分）

**目标**：创建三个仓库（local / remote / virtual）组成完整的 Docker 代理链。

**步骤**：

首先确认 profile 已加载：
```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
```

运行：
```bash
bash modules/artifactory-docker/create-repo.sh $NICKNAME
```

预期输出：
```
Creating Artifactory repositories for <nickname> (artifactory-docker)...
    ✅ Created: <nickname>-docker-local
    ✅ Created: <nickname>-docker-remote
    ✅ Created: <nickname>-docker-virtual
✅ Repositories ready for <nickname>
```

**成功标志**：三个仓库在 JFrog UI → Artifactory → Repositories 中可见。

---

### artifactory-docker-T2 — 通过 Artifactory 拉取 Docker 镜像（20 分）

**目标**：配置 Docker 登录 Artifactory，通过虚拟仓库拉取公共镜像并缓存。

**步骤**：

1. 获取你的 Artifactory 域名（去掉 `https://`）：
   ```bash
   JFROG_DOMAIN=$(echo $JFROG_URL | sed 's|https://||')
   echo $JFROG_DOMAIN
   ```

2. Docker 登录 Artifactory：
   ```bash
   docker login ${JFROG_DOMAIN} -u $JFROG_USER -p $JFROG_TOKEN
   ```
   > 如果没有 `JFROG_USER`，使用 `workshop` 或询问讲师。

3. 通过虚拟仓库拉取镜像：
   ```bash
   docker pull ${JFROG_DOMAIN}/${NICKNAME}-docker-virtual/alpine:3.18
   ```

**成功标志**：拉取成功，`{nickname}-docker-remote-cache` 仓库中出现缓存内容。

**知识点**：通过 Artifactory 代理拉取后，镜像被缓存在远程代理仓库中——即使 Docker Hub 不可用，后续拉取也能命中缓存。

---

### artifactory-docker-T3 — 构建并推送 Docker 镜像到 Artifactory（20 分）

**目标**：用示例 Dockerfile 构建自定义镜像，推送到个人 local 仓库，并记录 Build Info。

**步骤**：

1. 进入示例项目：
   ```bash
   cd modules/artifactory-docker/sample-project
   ```

2. 配置 JFrog CLI（如已配置可跳过）：
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

3. 构建镜像（通过 JFrog CLI 记录 Build Info）：
   ```bash
   jf docker build \
     -t ${JFROG_DOMAIN}/${NICKNAME}-docker-local/workshop-app:1.0 \
     --build-name=${NICKNAME}-docker-build \
     --build-number=1 \
     .
   ```

4. 推送镜像：
   ```bash
   jf docker push \
     ${JFROG_DOMAIN}/${NICKNAME}-docker-local/workshop-app:1.0 \
     --build-name=${NICKNAME}-docker-build \
     --build-number=1
   ```

**成功标志**：`{nickname}-docker-local` 仓库中出现 `workshop-app` 镜像。

---

### artifactory-docker-T4 — 发布 Docker Build Info 到 Artifactory（20 分）

**目标**：将构建元数据发布至 Artifactory，记录镜像的完整依赖层信息。

**步骤**：

```bash
jf rt build-collect-env ${NICKNAME}-docker-build 1
jf rt build-publish ${NICKNAME}-docker-build 1
```

在 Artifactory UI 中验证：
**Artifactory → Builds → `{nickname}-docker-build`**

**成功标志**：Builds 列表中存在该记录，点击可查看镜像层和环境信息。

**知识点**：Docker Build Info 记录了每一层镜像对应的基础镜像版本，是容器供应链安全审计的基础。

---

## 故障排查

**docker login 报 401**：确认 `JFROG_TOKEN` 有效，且用户有访问该仓库的权限。

**docker pull 报 not found**：确认虚拟仓库名称正确，且远程仓库配置了代理 Docker Hub。

**jf docker build 报 unknown flag**：确认 JFrog CLI 版本 ≥ 2.x，运行 `jf --version` 检查。

**Build Info 找不到**：确认 `jf docker push` 时带了 `--build-name` 和 `--build-number` 参数。
