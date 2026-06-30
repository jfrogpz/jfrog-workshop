---
applyTo: "modules/artifactory-maven/**"
---

# artifactory-maven 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **artifactory-maven** 模块。本模块聚焦于 Maven 制品代理：在 Artifactory 中建立个人 Maven 仓库组，通过 Artifactory 解析 Java 依赖，完成构建并发布 Build Info。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块目标

以 Artifactory 作为 Maven 依赖的统一代理：所有 Maven 依赖下载经过 Artifactory 缓存，构建产物发布至个人本地仓库，配合 Build Info 实现完整的 Java 制品追溯。

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| artifactory-maven-T1 | 在 Artifactory 中创建个人 Maven 仓库 | 10 | `{nickname}-maven-virtual` 仓库存在 |
| artifactory-maven-T2 | 通过 Artifactory 完成首次 Maven 构建 | 20 | `{nickname}-maven-remote-cache` 中有缓存的依赖 |
| artifactory-maven-T3 | 发布 Maven Build Info 到 Artifactory | 20 | `{nickname}-maven-build` Build Info 存在 |
| **总计** | | **50** | |

**前置条件**：已安装 Java JDK 11+ 和 Maven 3.6+，无需额外 JFrog 功能。

---

## 任务详情

### artifactory-maven-T1 — 在 Artifactory 中创建个人 Maven 仓库（10 分）

**目标**：创建三个 Maven 仓库（local / remote / virtual）组成完整代理链。

**步骤**：

首先确认 profile 已加载：
```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
```

运行：
```bash
bash modules/artifactory-maven/create-repo.sh $NICKNAME
```

预期输出：
```
Creating Artifactory repositories for <nickname> (artifactory-maven)...
    ✅ Created: <nickname>-maven-local
    ✅ Created: <nickname>-maven-remote
    ✅ Created: <nickname>-maven-virtual
✅ Repositories ready for <nickname>
```

**成功标志**：三个仓库在 JFrog UI → Artifactory → Repositories 中可见。

---

### artifactory-maven-T2 — 通过 Artifactory 完成首次 Maven 构建（20 分）

**目标**：配置 Maven 通过 Artifactory 虚拟仓库解析依赖，完成构建并缓存依赖包。

**步骤**：

1. 配置 JFrog CLI（如已配置可跳过）：
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

2. 进入示例项目：
   ```bash
   cd modules/artifactory-maven/sample-project
   ```

3. 配置 Maven 通过 Artifactory 解析依赖：
   ```bash
   jf mvnc \
     --repo-resolve-releases=${NICKNAME}-maven-virtual \
     --repo-resolve-snapshots=${NICKNAME}-maven-virtual \
     --repo-deploy-releases=${NICKNAME}-maven-local \
     --repo-deploy-snapshots=${NICKNAME}-maven-local
   ```

4. 执行构建：
   ```bash
   jf mvn clean install \
     --build-name=${NICKNAME}-maven-build \
     --build-number=1
   ```

**成功标志**：构建成功（`BUILD SUCCESS`），`{nickname}-maven-remote-cache` 中有缓存的依赖。

**知识点**：通过 Artifactory 代理 Maven Central，所有下载的 jar 都会被缓存——上游不可用时构建仍能正常进行，同时获得完整的依赖可见性。

---

### artifactory-maven-T3 — 发布 Maven Build Info 到 Artifactory（20 分）

**目标**：将构建元数据（依赖列表、模块信息、环境变量）发布至 Artifactory，实现完整追溯。

**步骤**：

```bash
jf rt build-collect-env ${NICKNAME}-maven-build 1
jf rt build-publish ${NICKNAME}-maven-build 1
```

在 Artifactory UI 中验证：
**Artifactory → Builds → `{nickname}-maven-build`**

**成功标志**：Builds 列表中存在该记录，点击可查看依赖树和模块信息。

**知识点**：Maven Build Info 包含每个模块的依赖解析路径，是 Java 供应链安全审计的基础数据。

---

## 故障排查

**`jf mvn` 命令找不到**：确认 JFrog CLI 版本 ≥ 2.x，运行 `jf --version`；确认已执行 `jf config use workshop`。

**构建报 401 / 403**：确认 `jf config show` 中 URL 和 Token 正确；确认 `{nickname}-maven-virtual` 仓库存在。

**依赖下载失败（connection refused）**：检查远程仓库 `{nickname}-maven-remote` 是否正确配置代理 Maven Central（`https://repo1.maven.org/maven2`）。

**Build Info 发布失败**：确认 `jf mvn` 时带了 `--build-name` 和 `--build-number` 参数，否则没有构建信息可发布。
