#!/bin/bash
set -e

echo ""
echo "=========================================="
echo "  JFrog Workshop 环境初始化"
echo "=========================================="
echo ""

# 安装 JFrog CLI
echo "正在安装 JFrog CLI..."
curl -fL https://install-cli.jfrog.io | sh
echo ""

# 验证必要工具
check_tool() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "  ✅ $1 $($1 --version 2>&1 | head -1)"
  else
    echo "  ❌ $1 未找到，请联系讲师" >&2
    exit 1
  fi
}

echo "正在检查工具..."
check_tool jf
check_tool node
check_tool npm
check_tool git
echo ""

# 确保脚本可执行
chmod +x "$(dirname "$0")/../automation/"*.sh 2>/dev/null || true

echo "=========================================="
echo "  🎉 环境就绪！"
echo "=========================================="
echo ""
echo "  接下来请："
echo "  1. 点击左侧菜单栏的 GitHub Copilot Chat 图标 (💬)"
echo "  2. 在对话框中输入："
echo ""
echo '     我要开始 workshop，EVENT_ID 是 <讲师提供的ID>'
echo ""
echo "  AI 助理将引导你完成所有任务。祝你好运！🚀"
echo ""
