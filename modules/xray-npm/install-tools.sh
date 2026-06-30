#!/bin/bash
# xray-npm module: verify required tools are available
# xray-npm 模块：验证所需工具是否可用

set -e

check_tool() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "✅ $1 found: $(command -v "$1")"
  else
    echo "❌ $1 not found" >&2
    return 1
  fi
}

check_tool node
check_tool npm
check_tool jf

echo "✅ All required tools for xray-npm are available"
