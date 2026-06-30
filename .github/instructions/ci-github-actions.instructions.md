---
applyTo: "modules/ci-github-actions/**"
---

# ci-github-actions 模块 — AI 助理指南

你正在引导学员完成 JFrog Workshop 的 **ci-github-actions** 模块。本模块聚焦于在 GitHub Actions 中集成 JFrog CLI：创建 Artifactory 仓库，配置 `setup-jfrog-cli` Action，在 CI 流水线中完成 npm 构建、发布制品、提交 Build Info，并触发 Xray 扫描。

学员已选择本模块。请按顺序引导他们完成以下任务。**不要跟随其他模块的指令。**

---

## 模块目标

在 GitHub Actions CI 流水线中集成 JFrog Platform：通过官方 `setup-jfrog-cli` Action 认证，npm 包通过 Artifactory 虚拟仓库解析，构建产物发布至 Artifactory，Build Info 提供完整溯源，Xray 扫描在 CI 中自动触发。

---

## 模块概述

| 任务 | 描述 | 分值 | 验证方式 |
|------|------|------|---------|
| ci-github-actions-T1 | 为 GitHub Actions 构建创建 Artifactory 仓库 | 10 | `{nickname}-npm-gha-virtual` 仓库存在 |
| ci-github-actions-T2 | 在 GitHub Actions Workflow 中配置 JFrog CLI | 20 | `{nickname}-npm-gha-remote` 缓存有内容（workflow 已运行）|
| ci-github-actions-T3 | 运行 Workflow 并发布制品到 Artifactory | 20 | `{nickname}-npm-gha-local` 中有制品 |
| ci-github-actions-T4 | 从 GitHub Actions 发布 Build Info 到 Artifactory | 20 | `{nickname}-gha-build/1` Build Info 存在 |
| ci-github-actions-T5 | 对 GitHub Actions 构建触发 Xray 扫描 | 20 | Xray 扫描结果存在 |
| **总计** | | **90** | |

**前置条件**：拥有 GitHub 账号和一个可以启用 Actions 的仓库；JFrog URL 和 Access Token 准备好作为 GitHub Secrets 配置。

---

## 任务详情

### ci-github-actions-T1 — 创建 Artifactory 仓库（10 分）

**目标**：创建三个启用 Xray 的 npm 仓库供 GitHub Actions 流水线使用。

**步骤**：

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/ci-github-actions/create-repo.sh $NICKNAME
```

预期输出：
```
Creating Artifactory repositories for <nickname> (ci-github-actions)...
    ✅ Created: <nickname>-npm-gha-local
    ✅ Created: <nickname>-npm-gha-remote
    ✅ Created: <nickname>-npm-gha-virtual
✅ Repositories ready for <nickname>
```

---

### ci-github-actions-T2 — 在 GitHub Actions 中配置 JFrog CLI（20 分）

**目标**：在 GitHub 仓库中添加 JFrog 认证信息，使 GitHub Actions workflow 能使用 JFrog CLI。

**步骤**：

1. **Fork 或创建 GitHub 仓库**，将 `modules/ci-github-actions/sample-project/` 中的文件复制进去。

2. **配置 GitHub Secrets**（Settings → Secrets and variables → Actions）：
   - `JFROG_URL` = `${JFROG_URL}`（你的 JFrog 实例 URL）
   - `JFROG_ACCESS_TOKEN` = `${JFROG_TOKEN}`（你的 Access Token）
   - `NICKNAME` = `${NICKNAME}`（你的昵称）

3. **验证 workflow 文件** `.github/workflows/jfrog-build.yml` 已包含：
   ```yaml
   - name: Setup JFrog CLI
     uses: jfrog/setup-jfrog-cli@v4
     env:
       JF_URL: ${{ secrets.JFROG_URL }}
       JF_ACCESS_TOKEN: ${{ secrets.JFROG_ACCESS_TOKEN }}
   ```

4. **触发 workflow**：push 一次 commit 或手动触发（Actions → Run workflow）。

**成功标志**：Workflow 运行成功，`{nickname}-npm-gha-remote` 中有缓存内容。

**知识点**：`jfrog/setup-jfrog-cli` 是官方 GitHub Action，它自动安装 JFrog CLI 并配置认证——一行配置替代了手动安装和 `jf config add` 步骤，适合 CI 环境使用。

---

### ci-github-actions-T3 — 运行 Workflow 并发布制品（20 分）

**目标**：确认 GitHub Actions workflow 成功完成 npm 构建并将制品上传至 Artifactory local 仓库。

**验证**：

Workflow 成功运行后，在 JFrog UI 中确认：
**Artifactory → Repositories → `{nickname}-npm-gha-local`** 中有内容。

workflow 中的关键步骤：
```yaml
- name: Configure npm to use Artifactory
  run: |
    jf npmc \
      --repo-resolve=${{ secrets.NICKNAME }}-npm-gha-virtual \
      --repo-deploy=${{ secrets.NICKNAME }}-npm-gha-local

- name: Install dependencies
  run: |
    jf npm install \
      --build-name=${{ env.BUILD_NAME }} \
      --build-number=${{ env.BUILD_NUMBER }}
```

**成功标志**：`{nickname}-npm-gha-local` 仓库中有制品（npm 包缓存或发布内容）。

---

### ci-github-actions-T4 — 发布 Build Info（20 分）

**目标**：确认 workflow 成功发布 Build Info 至 Artifactory。

**workflow 中的关键步骤**：
```yaml
- name: Collect environment variables
  run: jf rt build-collect-env ${{ env.BUILD_NAME }} ${{ env.BUILD_NUMBER }}

- name: Publish Build Info
  run: jf rt build-publish ${{ env.BUILD_NAME }} ${{ env.BUILD_NUMBER }}
```

**在 JFrog UI 验证**：Artifactory → Builds → `{nickname}-gha-build`

**成功标志**：Build Info 记录存在，可查看依赖列表和环境信息。

**知识点**：在 CI 中发布 Build Info 使每次 GitHub Actions 运行都与 Artifactory 中的制品关联，实现从 commit → CI run → artifact → Xray scan 的完整追溯链。

---

### ci-github-actions-T5 — 触发 Xray 扫描（20 分）

**目标**：确认 workflow 触发了 Xray 扫描并在 JFrog UI 中可查看结果。

**workflow 中的关键步骤**：
```yaml
- name: Trigger Xray Scan
  run: |
    jf rt build-scan ${{ env.BUILD_NAME }} ${{ env.BUILD_NUMBER }} || true
```

**在 JFrog UI 验证**：Xray → Scans List → `{nickname}-gha-build`

**成功标志**：Xray 扫描结果存在，可查看 CVE 报告。

**知识点**：在 CI 中使用 `|| true` 是让 Xray 扫描以非阻断模式运行——扫描结果会被记录，但不会因漏洞导致 CI 失败。生产环境中可去掉 `|| true` 使漏洞阻断 CI。

---

## 故障排查

**Workflow 报 "JFROG_URL not set"**：确认 GitHub Secrets 已正确配置（区分大小写）；确认 workflow 文件引用的 secret 名称与配置一致。

**`jf npmc` 报错**：确认 JFrog CLI 已通过 `setup-jfrog-cli` Action 安装；确认仓库名称正确。

**Build Info 发布失败**：确认 `jf npm install` 时带了 `--build-name` 和 `--build-number`；确认 `build-collect-env` 步骤在 `build-publish` 之前执行。

**Xray 扫描无结果**：等待 2-3 分钟；确认仓库已启用 Xray 索引（`create-repo.sh` 已设置 `xrayIndex: true`）。
