---
applyTo: "modules/jas-maven/**"
---

# jas-maven 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **jas-maven** 模块。本模块聚焦于 JFrog Advanced Security（JAS）与 Maven 项目的集成：创建 Maven 仓库，构建并发布包含 Log4Shell 漏洞的项目，运行 CVE 扫描、SAST 静态分析、密钥检测，并在 JFrog UI 中查看上下文可达性分析结果。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块目标

使用 Maven 项目体验 JFrog Advanced Security 的完整扫描能力：
- **CVE 扫描**：检测 Log4Shell（CVE-2021-44228）等高危漏洞
- **SAST**：静态代码分析，发现代码层面的安全问题
- **Secrets 检测**：发现 `App.java` 中硬编码的 API 密钥
- **上下文分析（Contextual Analysis）**：基于 JAR 构建内容，判断哪些 CVE 实际可触达

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| jas-maven-T1 | 创建个人 Maven 仓库 | 10 | `{nickname}-maven-jas-virtual` 仓库存在 |
| jas-maven-T2 | 通过 Artifactory 构建并发布 Build Info | 20 | `{nickname}-jas-maven-build/1` Build Info 存在 |
| jas-maven-T3 | 运行 jf audit --mvn 扫描 CVE | 20 | Maven remote 缓存有内容（依赖已解析）|
| jas-maven-T4 | 使用 JAS 检测硬编码密钥 | 20 | Maven remote 缓存有内容（audit 已运行）|
| jas-maven-T5 | 在 JFrog UI 中查看上下文分析结果 | 20 | 手动验证 |
| **总计** | | **90** | |

**前置条件**：已安装 JFrog CLI、Java 11+、Maven（或使用项目内置的 Maven Wrapper `./mvnw`）。

---

## 任务详情

### jas-maven-T1 — 创建 Maven 仓库（10 分）

**步骤**：

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/jas-maven/create-repo.sh $NICKNAME
```

预期结果：
```
Creating Artifactory repositories for <nickname> (jas-maven)...
    ✅ Created: <nickname>-maven-jas-local
    ✅ Created: <nickname>-maven-jas-remote
    ✅ Created: <nickname>-maven-jas-virtual
✅ Repositories ready for <nickname>
```

---

### jas-maven-T2 — 构建并发布 Build Info（20 分）

**目标**：通过 JFrog CLI 构建 Maven 项目，将依赖解析走 Artifactory，并将 Build Info 发布到 JFrog Platform。

**步骤**：

1. 配置 JFrog CLI Maven 解析仓库：
   ```bash
   cd modules/jas-maven/sample-project
   jf mvnc \
     --repo-resolve-releases=$NICKNAME-maven-jas-virtual \
     --repo-resolve-snapshots=$NICKNAME-maven-jas-virtual \
     --repo-deploy-releases=$NICKNAME-maven-jas-local \
     --repo-deploy-snapshots=$NICKNAME-maven-jas-local
   ```

2. 构建项目：
   ```bash
   jf mvn install \
     --build-name=${NICKNAME}-jas-maven-build \
     --build-number=1
   ```

3. 发布 Build Info：
   ```bash
   jf rt build-collect-env ${NICKNAME}-jas-maven-build 1
   jf rt build-publish ${NICKNAME}-jas-maven-build 1
   ```

**成功标志**：在 JFrog UI 中 Artifactory → Builds → `{nickname}-jas-maven-build` 可查看构建。

---

### jas-maven-T3 — 扫描 Maven CVE（20 分）

**目标**：运行 `jf audit` 扫描 Maven 依赖中的已知漏洞，重点关注 Log4Shell。

```bash
cd modules/jas-maven/sample-project
jf audit --mvn
```

**预期发现**：
- **CVE-2021-44228**（Log4Shell）：log4j-core 2.14.1 — Critical
- **CVE-2015-7501**：commons-collections 3.2.1 — High（反序列化）

**成功标志**：命令输出包含 CVE 列表；`{nickname}-maven-jas-remote` 仓库有缓存内容。

**知识点**：`jf audit --mvn` 在本地分析依赖树，通过 JFrog 漏洞数据库（VulnDB）匹配 CVE，无需上传代码到服务器。

---

### jas-maven-T4 — 检测硬编码密钥（20 分）

**目标**：使用 JAS Secrets 检测功能，发现 `App.java` 中硬编码的 API Key。

```bash
cd modules/jas-maven/sample-project
jf audit --mvn --secrets
```

**预期发现**：在 `src/main/java/com/jfrog/workshop/App.java` 中检测到硬编码的 API Key（`sk-1234...`）。

**成功标志**：扫描报告显示 Secrets 发现。

**知识点**：JAS Secrets 检测使用机器学习模型识别代码中的凭证模式（API Keys、密码、OAuth Token 等），支持多种密钥格式的高精度检测。

---

### jas-maven-T5 — 查看上下文分析结果（20 分）

**目标**：在 JFrog UI 中查看上下文分析（Contextual Analysis）结果，了解哪些 CVE 在实际代码中可触达。

**步骤**：

1. 在 JFrog UI 中进入：**Xray → Scans List → `{nickname}-jas-maven-build`**
2. 点击 CVE-2021-44228（Log4Shell）
3. 查看 **Contextual Analysis** 标签
4. 确认：`App.java` 的 `logger.error()` 调用使 Log4Shell 标记为 **APPLICABLE**（实际可触达）

**知识点**：
- **APPLICABLE**：代码中存在实际触发漏洞的调用路径
- **NOT APPLICABLE**：虽然引入了漏洞包，但代码中没有可触达的利用路径
- Maven JAR 包含完整字节码，JAS 可精确分析调用链——这正是 Maven 项目比纯脚本项目更适合上下文分析的原因

此为手动验证任务，完成 UI 检查后即可标记完成。

---

## 故障排查

**`jf mvnc` 报错**：确认 JFrog CLI 已配置（`jf config show`）；确认仓库名正确。

**`jf mvn install` 构建失败**：确认 Java 版本 ≥ 11（`java -version`）；确认已在 `modules/jas-maven/sample-project` 目录下执行。

**CVE 扫描显示 "No vulnerabilities found"**：确认 JFrog CLI 已连接到配置了 Xray 的实例；运行 `jf config show` 确认服务地址正确。

**Contextual Analysis 未显示**：等待 2-3 分钟让 Xray 完成扫描；确认 Build Info 已成功发布（T2）。
