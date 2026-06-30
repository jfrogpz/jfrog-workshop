#!/bin/bash
# curation-docker module: verify required tools are available
# curation-docker 模块：验证所需工具是否可用

set -e

check_tool() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "✅ $1 found: $(command -v "$1")"
  else
    echo "❌ $1 not found" >&2
    return 1
  fi
}

check_tool docker
check_tool jf

echo "✅ All required tools for curation-docker are available"
