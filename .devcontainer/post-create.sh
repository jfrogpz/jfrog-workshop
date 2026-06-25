#!/bin/bash
set -e

echo ""
echo "=========================================="
echo "  JFrog Workshop Environment Setup / 环境初始化"
echo "=========================================="
echo ""

# 安装 JFrog CLI
echo "Installing JFrog CLI / 正在安装 JFrog CLI..."
curl -fL https://install-cli.jfrog.io | sh
echo ""

# 验证必要工具
check_tool() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "  ✅ $1 $($1 --version 2>&1 | head -1)"
  else
    echo "  ❌ $1 not found, please contact your instructor / 未找到，请联系讲师" >&2
    exit 1
  fi
}

echo "Checking required tools / 正在检查工具..."
check_tool jf
check_tool node
check_tool npm
check_tool git
echo ""

# 确保脚本可执行
chmod +x "$(dirname "$0")/../automation/"*.sh 2>/dev/null || true

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
