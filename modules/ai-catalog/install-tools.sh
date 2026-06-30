#!/bin/bash
# ai-catalog: verify required tools
echo "Checking tools for ai-catalog module..."

if ! command -v jf &>/dev/null; then
  echo "❌ JFrog CLI (jf) not found. Install from: https://jfrog.com/getcli/" >&2
  exit 1
fi
echo "  ✅ JFrog CLI: $(jf --version 2>&1 | head -1)"

if ! command -v python3 &>/dev/null; then
  echo "❌ Python 3 not found. Install from: https://www.python.org/downloads/" >&2
  exit 1
fi
echo "  ✅ Python 3: $(python3 --version)"

if ! python3 -c "import huggingface_hub" 2>/dev/null; then
  echo "  ⚠️  huggingface_hub not installed. Run: pip install huggingface_hub"
  echo "      This is required for downloading models in T3."
else
  echo "  ✅ huggingface_hub: $(python3 -c 'import huggingface_hub; print(huggingface_hub.__version__)')"
fi

echo "✅ Tools check complete."
