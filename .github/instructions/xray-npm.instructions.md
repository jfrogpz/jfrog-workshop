---
applyTo: "modules/xray-npm/**"
---

# xray-npm 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **xray-npm** 模块。本模块聚焦于 Xray 漏洞扫描：通过 Artifactory 完成 npm 构建并发布 Build Info，然后创建 Xray 安全策略和 Watch，对构建进行扫描并查看 CVE 结果。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块目标

使用 JFrog Xray 对 npm 依赖进行安全扫描：配置安全策略定义 CVE 严重性阈值，创建 Watch 关联资源，对构建制品执行扫描，并在 UI 中查看漏洞详情与修复建议。

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| xray-npm-T1 | 在 Artifactory 中创建个人 npm 仓库 | 10 | `{nickname}-npm-xray-virtual` 仓库存在 |
| xray-npm-T2 | 完成 npm 构建并发布 Build Info | 20 | `{nickname}-xray-npm-build/1` Build Info 存在 |
| xray-npm-T3 | 创建 Xray 安全策略 | 20 | 策略名称包含昵称，类型为 Security |
| xray-npm-T4 | 创建 Xray Watch 监控构建 | 20 | Watch 名称包含昵称 |
| xray-npm-T5 | 触发 Xray 扫描并查看 CVE 结果 | 20 | 手动验证（UI 探索）|
| **总计** | | **90** | |

**前置条件**：JFrog 实例已启用 Xray，且具有扫描 npm 包的权限。

---

## 任务详情

### xray-npm-T1 — 在 Artifactory 中创建个人 npm 仓库（10 分）

**目标**：创建三个启用 Xray 索引的 npm 仓库（local / remote / virtual）。

**步骤**：

首先确认 profile 已加载：
```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
```

运行：
```bash
bash modules/xray-npm/create-repo.sh $NICKNAME
```

预期输出：
```
Creating Artifactory repositories for <nickname> (xray-npm)...
    ✅ Created: <nickname>-npm-xray-local
    ✅ Created: <nickname>-npm-xray-remote
    ✅ Created: <nickname>-npm-xray-virtual
✅ Repositories ready for <nickname>
```

**成功标志**：三个仓库在 JFrog UI → Artifactory → Repositories 中可见，且 Xray 索引已启用。

---

### xray-npm-T2 — 完成 npm 构建并发布 Build Info（20 分）

**目标**：通过 Artifactory 完成 npm 安装，将构建信息发布至 Artifactory 供 Xray 扫描。

**步骤**：

1. 配置 JFrog CLI（如已配置可跳过）：
   ```bash
   jf config add workshop --url=$JFROG_URL --access-token=$JFROG_TOKEN --interactive=false
   jf config use workshop
   ```

2. 配置 npm 指向 Artifactory 虚拟仓库：
   ```bash
   jf npmc --repo-resolve=${NICKNAME}-npm-xray-virtual --repo-deploy=${NICKNAME}-npm-xray-local
   ```

3. 进入示例项目并执行构建：
   ```bash
   cd modules/xray-npm/sample-project
   jf npm install --build-name=${NICKNAME}-xray-npm-build --build-number=1
   ```

4. 发布 Build Info：
   ```bash
   jf rt build-collect-env ${NICKNAME}-xray-npm-build 1
   jf rt build-publish ${NICKNAME}-xray-npm-build 1
   ```

**成功标志**：在 Artifactory UI → Builds → `{nickname}-xray-npm-build` 中可见构建记录。

**知识点**：Build Info 包含所有依赖的完整清单，是 Xray 扫描的数据来源——Xray 通过对比 Build Info 中的包信息与漏洞数据库来检测 CVE。

---

### xray-npm-T3 — 创建 Xray 安全策略（20 分）

**目标**：创建一个 Security 类型的 Xray 策略，定义对 High/Critical CVE 的处置规则。

**步骤**：

1. 打开 JFrog UI → Xray → Policies
2. 点击 **New Policy**
3. 填写：
   - **Name**：`{NICKNAME}-security-policy`（名称必须包含你的昵称）
   - **Type**：Security
4. 点击 **New Rule**，填写：
   - **Rule Name**：`block-high-cve`
   - **Min Severity**：High
   - **Actions**：Block download（可选）
5. 保存策略

**成功标志**：在 Xray → Policies 中可见策略，名称包含你的昵称。

**知识点**：Xray 策略定义什么样的漏洞会触发违规。策略本身不会自动扫描——需要通过 Watch 将策略与资源（仓库或构建）关联起来。

---

### xray-npm-T4 — 创建 Xray Watch 监控构建（20 分）

**目标**：创建一个 Xray Watch，将你的 npm 仓库与安全策略关联，启用持续监控。

**步骤**：

1. 打开 JFrog UI → Xray → Watches
2. 点击 **New Watch**
3. 填写：
   - **Name**：`{NICKNAME}-npm-watch`（名称必须包含你的昵称）
4. 在 **Resources** 中添加资源：
   - 选择 **Repositories**，搜索并添加 `{NICKNAME}-npm-xray-local` 和 `{NICKNAME}-npm-xray-remote`
   - 或选择 **Builds**，添加 `{NICKNAME}-xray-npm-build`
5. 在 **Assigned Policies** 中添加你的策略：`{NICKNAME}-security-policy`
6. 保存 Watch

**成功标志**：在 Xray → Watches 中可见 Watch，名称包含你的昵称，已关联策略。

**知识点**：Watch 是 Xray 的扫描触发器——它将"扫什么"（资源）和"怎么判断"（策略）连接起来。Watch 创建后，Xray 会自动对已索引的内容触发扫描。

---

### xray-npm-T5 — 触发 Xray 扫描并查看 CVE 结果（20 分）

**目标**：手动触发扫描（如需要），在 UI 中查看 CVE 详情，理解漏洞报告结构。

**步骤**：

1. 打开 JFrog UI → Xray → Scans List
2. 查找你的构建 `{NICKNAME}-xray-npm-build`
3. 点击进入，查看：
   - **Violations**：哪些 CVE 触发了你的策略
   - **CVE 详情**：CVSS 评分、受影响版本、修复版本
   - **依赖路径**：哪个直接依赖引入了漏洞

也可以通过以下方式触发扫描：
```bash
jf rt build-scan ${NICKNAME}-xray-npm-build 1
```

**本任务为手动验证，探索完 UI 后直接运行进度检查即可得分。**

**知识点**：`axios@1.7.2` 包含已知 CVE，在 Xray 扫描结果中应该可以看到相关漏洞报告。修复方式是升级至 `1.7.7` 或更高版本。

---

## 故障排查

**仓库创建失败（401/403）**：确认 `JFROG_URL` 和 `JFROG_TOKEN` 已正确设置；确认 Token 有创建仓库的权限（Admin 或 Manage Repositories）。

**`jf npm install` 报错 404**：确认 `{nickname}-npm-xray-virtual` 已创建；确认 `jf npmc` 配置已指向正确的虚拟仓库。

**Build Info 发布失败**：确认 `jf npm install` 时带了 `--build-name` 和 `--build-number` 参数。

**Xray 扫描结果为空**：Xray 索引需要时间（通常 1-3 分钟）；确认仓库已启用 Xray 索引（`create-repo.sh` 已自动设置 `xrayIndex: true`）。

**看不到 Xray 菜单**：确认 JFrog 实例已激活 Xray 许可证；联系讲师确认环境配置。
