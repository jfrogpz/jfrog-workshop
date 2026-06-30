#!/bin/bash
# npm-basic module: verify or install required tools
# npm-basic 模块：检查或安装所需工具
#
# ── MANUAL SETUP (without Codespace) / 手动配置说明 ──────────────────────────
# This module requires the following tools / 本模块需要以下工具：
#
#   - Node.js v18+   https://nodejs.org
#                    macOS: brew install node
#                    Ubuntu/Debian: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs
#
#   - npm            Included with Node.js / 随 Node.js 一同安装
#
# After installing, verify with / 安装后验证：
#   node -v
#   npm -v
# ─────────────────────────────────────────────────────────────────────────────

set -e

# ── node ──────────────────────────────────────────────────────────────────────
if command -v node >/dev/null 2>&1; then
  echo "  ✅ node $(node --version)"
else
  echo "  Installing Node.js / 安装 Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
  echo "  ✅ node $(node --version)"
fi

# ── npm ───────────────────────────────────────────────────────────────────────
if command -v npm >/dev/null 2>&1; then
  echo "  ✅ npm $(npm --version)"
else
  echo "  ❌ npm not found after Node.js install — check Node.js installation" >&2
  exit 1
fi
