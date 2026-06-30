#!/bin/bash
# artifactory-docker module: verify or install required tools
# artifactory-docker 模块：检查或安装所需工具
#
# ── MANUAL SETUP (without Codespace) / 手动配置说明 ──────────────────────────
# This module requires the following tools / 本模块需要以下工具：
#
#   - Docker Engine   https://docs.docker.com/engine/install/
#                     macOS: Install Docker Desktop
#                     Ubuntu: sudo apt-get install docker.io
#
# After installing, verify with / 安装后验证：
#   docker --version
# ─────────────────────────────────────────────────────────────────────────────

set -e

if command -v docker >/dev/null 2>&1; then
  echo "  ✅ docker $(docker --version | awk '{print $3}' | tr -d ',')"
else
  echo "  ❌ Docker not found. Please install Docker Desktop or Docker Engine." >&2
  echo "  ❌ 未找到 Docker，请安装 Docker Desktop 或 Docker Engine。" >&2
  exit 1
fi

echo "  ✅ All tools ready for artifactory-docker module"
