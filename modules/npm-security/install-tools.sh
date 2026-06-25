#!/bin/bash
# npm-security module: verify or install required tools
# npm-security 模块：检查或安装所需工具

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
