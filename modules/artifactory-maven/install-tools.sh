#!/bin/bash
# artifactory-maven module: verify or install required tools
# artifactory-maven 模块：检查或安装所需工具
#
# ── MANUAL SETUP (without Codespace) / 手动配置说明 ──────────────────────────
# This module requires the following tools / 本模块需要以下工具：
#
#   - Java (JDK 11+)  https://adoptium.net
#                     macOS: brew install temurin
#                     Ubuntu: sudo apt-get install -y default-jdk
#
#   - Maven 3.6+      https://maven.apache.org/download.cgi
#                     macOS: brew install maven
#                     Ubuntu: sudo apt-get install -y maven
#
# After installing, verify with / 安装后验证：
#   java -version
#   mvn -version
# ─────────────────────────────────────────────────────────────────────────────

set -e

# ── Java ──────────────────────────────────────────────────────────────────────
if command -v java >/dev/null 2>&1; then
  echo "  ✅ java $(java -version 2>&1 | head -1)"
else
  echo "  Installing Java / 安装 Java..."
  sudo apt-get install -y default-jdk
  echo "  ✅ java $(java -version 2>&1 | head -1)"
fi

# ── Maven ─────────────────────────────────────────────────────────────────────
if command -v mvn >/dev/null 2>&1; then
  echo "  ✅ mvn $(mvn --version | head -1)"
else
  echo "  Installing Maven / 安装 Maven..."
  sudo apt-get install -y maven
  echo "  ✅ mvn $(mvn --version | head -1)"
fi

echo "  ✅ All tools ready for artifactory-maven module"
