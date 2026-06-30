# JFrog Workshop — 开发者指引（Claude Code）

## 文件职责与同步原则

本项目中同一个概念（标签、术语、模块 ID、脚本参数等）往往同时存在于多个层：

- **数据层**：`docs/module-catalog.json` — 页面渲染的唯一数据源
- **前端层**：`docs/index.html` — 筛选器 chip、tooltip 文案、显示文字
- **AI 指令层**：`.claude/commands/update-tags.md`、`.github/instructions/*.md` — Claude 的判断依据
- **脚本层**：`automation/module-author/update-catalog-tags.sh` — 脚本内嵌的允许值和注释
- **文档层**：`guides/MODULE-AUTHOR.md`、`guides/MODULE-AUTHOR_EN.md` — 人类开发者参考的规范

**规则：任何概念的修改必须覆盖它存在的所有层。** 修改前先 grep 确认范围，改完后再 grep 验证无遗漏，最后一次性提交。

```bash
# 修改前
grep -rn "<概念>" .

# 修改后验证
grep -rn "<概念>" .
```

分批提交是错误的——中间状态会导致各层不一致。

---

## 操作模块前必读

在新建、改名、修改任务或更新标签**之前**，先加载模块设计原则：

```bash
cat guides/MODULE-AUTHOR.md
```

该文件第零节包含命名规范、产品线分类、标签语义、自包含原则等核心设计决策。

---

## 模块标签自动更新规则

每当创建或修改以下任意文件后，**无需等待开发者要求**，立即更新 `docs/module-catalog.json` 中对应模块的 `tags` 字段：

- `modules/<id>/tasks.json`
- `.github/instructions/<id>.instructions.md` 或 `<id>.instructions-en.md`
- `docs/module-catalog.json` 中某模块的 `desc_en` / `desc_zh`

更新时读取 `.claude/commands/update-tags.md` 中的完整标准（允许值、判断规则、注意事项），直接写入 `docs/module-catalog.json`。

---

## 可用指令

| 指令 | 用途 |
|------|------|
| `/update-tags` | 手动批量检查并更新所有模块的 catalog 标签 |
