#!/bin/bash
set -e

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

echo ""
echo "=========================================="
echo "  JFrog Workshop Environment Setup / 环境初始化"
echo "=========================================="
echo ""

# ── Install JFrog CLI ─────────────────────────────────────────────────────────
echo ">>> Installing JFrog CLI / 安装 JFrog CLI..."
curl -fL https://install-cli.jfrog.io | sh
echo "  ✅ jf $(jf --version 2>&1 | head -1)"
echo ""

# ── Run each module's install-tools.sh ────────────────────────────────────────
echo ">>> Installing module tools / 安装模块工具..."
FOUND=0
for INSTALL_SCRIPT in "${REPO_ROOT}"/modules/*/install-tools.sh; do
  if [ -f "$INSTALL_SCRIPT" ]; then
    MODULE=$(basename "$(dirname "$INSTALL_SCRIPT")")
    echo "  Module / 模块：${MODULE}"
    bash "$INSTALL_SCRIPT"
    FOUND=$((FOUND + 1))
  fi
done

if [ "$FOUND" -eq 0 ]; then
  echo "  (no module install-tools.sh found / 未找到模块安装脚本)"
fi
echo ""

# ── Verify git (always required) ──────────────────────────────────────────────
echo ">>> Checking git / 检查 git..."
if command -v git >/dev/null 2>&1; then
  echo "  ✅ git $(git --version)"
else
  echo "  ❌ git not found / 未找到 git" >&2
  exit 1
fi
echo ""

# ── Make scripts executable ───────────────────────────────────────────────────
chmod +x "${REPO_ROOT}/automation/"*.sh 2>/dev/null || true
find "${REPO_ROOT}/modules" -name "*.sh" -exec chmod +x {} \;

echo "=========================================="
echo "  🎉 Environment ready! / 环境就绪！"
echo "=========================================="
echo ""
echo "  Next steps / 接下来请："
echo "  1. The GitHub Copilot Chat panel is on the right side of the window — type directly."
echo "     右侧已内嵌 GitHub Copilot Chat 对话面板，直接输入消息即可。"
echo "  2. Type one of the following / 在对话框中输入："
echo ""
echo '     # Event mode / 参加赛事'
echo '     I want to start the workshop, my EVENT_ID is <ID provided by instructor>'
echo '     我要开始 workshop，EVENT_ID 是 <讲师提供的ID>'
echo ""
echo '     # Self-study / 自主学习'
echo '     I want to self-study / 我要自主学习'
echo ""
echo "  The AI assistant will guide you through all tasks. Good luck! / AI 助理将引导你完成所有任务。祝你好运！🚀"
echo ""
