#!/bin/bash
# jas-maven: verify required tools are available
echo "Checking tools for jas-maven module..."

if ! command -v jf &>/dev/null; then
  echo "❌ JFrog CLI (jf) not found. Install from: https://jfrog.com/getcli/" >&2
  exit 1
fi
echo "  ✅ JFrog CLI: $(jf --version 2>&1 | head -1)"

if ! command -v mvn &>/dev/null && ! command -v ./mvnw &>/dev/null; then
  echo "  ⚠️  Maven (mvn) not found. The sample project includes a Maven Wrapper (./mvnw) — no install needed."
else
  echo "  ✅ Maven: $(mvn --version 2>&1 | head -1)"
fi

if ! command -v java &>/dev/null; then
  echo "❌ Java not found. Install JDK 11+: https://adoptium.net/" >&2
  exit 1
fi
echo "  ✅ Java: $(java -version 2>&1 | head -1)"

echo "✅ All required tools are available."
