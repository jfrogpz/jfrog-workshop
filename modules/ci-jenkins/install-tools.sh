#!/bin/bash
# ci-jenkins module: verify required tools
set -e

# JFrog CLI
if command -v jf >/dev/null 2>&1; then
  echo "  ✅ jf $(jf --version 2>&1 | head -1)"
else
  echo "  Installing JFrog CLI..."
  curl -fL https://install-jf.jfrog.io | sh
  echo "  ✅ jf $(jf --version 2>&1 | head -1)"
fi

# curl (used for API calls)
if command -v curl >/dev/null 2>&1; then
  echo "  ✅ curl $(curl --version | head -1)"
else
  echo "  ❌ curl not found — please install curl" >&2
  exit 1
fi

echo "  ✅ All tools ready for ci-jenkins module"
echo "  ℹ️  Jenkins itself runs externally — ensure you have access to a Jenkins instance"
