---
applyTo: "modules/best-practices/**"
---

# best-practices 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **best-practices** 模块。本模块聚焦于 JFrog 平台治理规范：仓库命名约定、Group 团队访问控制、Permission Target 权限范围配置，以及 JFrog Project 环境隔离。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块目标

掌握 JFrog 平台企业级治理的四个核心实践：
1. **仓库命名规范**：local/remote/virtual 三层结构，按包类型分类
2. **Group 访问控制**：将用户按团队分组，统一管理权限
3. **Permission Target**：精细化控制谁能访问哪些仓库，拥有什么权限
4. **JFrog Project**：按项目/环境隔离资源，避免命名冲突

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| best-practices-T1 | 按命名规范创建 npm 仓库 | 10 | `{nickname}-npm-bp-virtual` 仓库存在 |
| best-practices-T2 | 创建 Group 实现团队访问控制 | 20 | `{nickname}-team` Group 存在 |
| best-practices-T3 | 创建 Permission Target 设置仓库访问范围 | 20 | `{nickname}-perm` Permission Target 存在 |
| best-practices-T4 | 创建 JFrog Project 实现环境隔离 | 20 | 以昵称为 key 的 Project 存在 |
| best-practices-T5 | 回顾治理架构（JFrog UI 检查） | 20 | 手动验证 |
| **总计** | | **90** | |

**前置条件**：有 JFrog 实例管理权限（Admin 或 Manage Groups/Permissions 权限）。

---

## 任务详情

### best-practices-T1 — 按命名规范创建仓库（10 分）

**目标**：按 JFrog 最佳实践创建三层 npm 仓库：本地仓库、远端缓存、虚拟仓库。

**命名规范**：`{nickname}-{packagetype}-{purpose}-{local|remote|virtual}`

**步骤**：

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/best-practices/create-repo.sh $NICKNAME
```

预期结果：
```
Creating Artifactory repositories for <nickname> (best-practices)...
    ✅ Created: <nickname>-npm-bp-local
    ✅ Created: <nickname>-npm-bp-remote
    ✅ Created: <nickname>-npm-bp-virtual
✅ Repositories ready for <nickname>
```

**知识点**：JFrog 推荐的仓库命名格式为 `{team}-{technology}-{purpose}-{type}`，例如 `myteam-npm-dev-virtual`。清晰的命名使得权限管理、审计和跨团队协作更加直观。

---

### best-practices-T2 — 创建 Group（20 分）

**目标**：创建一个团队 Group，将用户统一管理以便批量授权。

**步骤**：

1. 进入 JFrog UI → **Administration** → **Identity and Access** → **Groups**
2. 点击 **New Group**
3. 配置：
   - **Group Name**：`{NICKNAME}-team`（必须包含你的昵称）
   - **Description**：Workshop best practices demo team
   - **Members**：将自己的用户名加入
4. 点击 **Save**

**成功标志**：Group 列表中出现 `{nickname}-team`。

**知识点**：企业中通常按职能（dev-team、ops-team、security-team）或产品线（project-a-team）建 Group。之后只需将 Group 加入 Permission Target，新员工入职后加入 Group 即可自动获得所有权限——无需逐一配置。

---

### best-practices-T3 — 创建 Permission Target（20 分）

**目标**：创建 Permission Target，将你的仓库权限精确授予你的 Group。

**步骤**：

1. 进入 JFrog UI → **Administration** → **Identity and Access** → **Permissions**
2. 点击 **New Permission**
3. 配置：
   - **Permission Name**：`{NICKNAME}-perm`（必须包含你的昵称）
   - **Repositories**：选择 `{nickname}-npm-bp-local` 和 `{nickname}-npm-bp-virtual`
   - **Groups**：选择 `{nickname}-team`，权限选 **Read** + **Deploy/Cache** + **Annotate**
4. 点击 **Save**

**成功标志**：Permissions 列表中出现 `{nickname}-perm`。

**知识点**：Permission Target 是 JFrog 权限模型的核心。常见最佳实践：
- 对 virtual repo 授予 Read（消费者）
- 对 local repo 授予 Deploy（发布者）
- 永远不直接给个人用户授权，而是通过 Group

---

### best-practices-T4 — 创建 JFrog Project（20 分）

**目标**：创建 JFrog Project 实现跨团队资源隔离，将你的仓库纳入项目管理。

**步骤**：

1. 进入 JFrog UI → **Administration** → **Projects**
2. 点击 **New Project**
3. 配置：
   - **Project Name**：`{NICKNAME} Best Practices`
   - **Project Key**：昵称小写去连字符（例如 `alice123`）
   - **Storage Quota**：设置适当配额（如 5 GB）
4. 创建后，进入项目 → **Repositories** → 添加 `{nickname}-npm-bp-local` 等仓库
5. **Members** → 添加 `{nickname}-team`

**成功标志**：Projects 页面中出现你的项目。

**知识点**：JFrog Project 提供命名空间隔离，不同项目的仓库名可以相同（通过 project key 区分）。适合多团队、多产品线的大型企业，实现真正的资源隔离和独立配额管理。

---

### best-practices-T5 — 回顾治理架构（20 分）

**目标**：通过 JFrog UI 全面回顾你建立的治理架构，确认四层防护已就绪。

**检查清单**：

- [ ] **Artifactory → Repositories**：确认三层仓库命名规范（local/remote/virtual）
- [ ] **Administration → Groups**：确认 `{nickname}-team` 有成员
- [ ] **Administration → Permissions**：确认 `{nickname}-perm` 关联了正确的仓库和 Group
- [ ] **Administration → Projects**：确认项目包含你的仓库和团队

**治理架构总结**：

```
用户
  └── Group: {nickname}-team
        └── Permission Target: {nickname}-perm
              └── 仓库: {nickname}-npm-bp-local / -virtual
                    └── Project: {nickname}-project（资源隔离边界）
```

此为手动验证任务，完成检查后即可标记完成。

---

## 故障排查

**Group 创建后看不到**：刷新页面，Groups 列表有时延迟几秒。

**Permission Target 无法选择仓库**：确认仓库已创建（T1 完成）；搜索时用昵称前缀过滤。

**Project Key 冲突**：JFrog Project Key 全实例唯一，如果昵称带连字符（如 `alice-123`），去掉连字符后再试（`alice123`）；实在冲突可在末尾加数字。

**无权限创建 Group / Project**：需要 Admin 或 Manage Groups/Projects 角色。联系讲师提升权限。
