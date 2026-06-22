#!/bin/bash
# 清除学员个人 Artifactory 远程仓库中的 axios@1.7.2 缓存
# 在 T5 安装前执行，确保 Curation Policy 能够拦截

set -eu

PROFILE_FILE="${HOME}/.workshop-profile"

if [ ! -f "$PROFILE_FILE" ]; then
  echo "❌ 未找到 ~/.workshop-profile，请先完成注册（T1）" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$PROFILE_FILE"

: "${NICKNAME:?}" "${JFROG_URL:?}" "${JFROG_TOKEN:?}"
JFROG_URL="${JFROG_URL%/}"

REMOTE_REPO="${NICKNAME}-npm-remote"
AXIOS_PATH="axios/-/axios-1.7.2.tgz"

echo ""
echo ">>> 清除 Artifactory 远程仓库缓存：${REMOTE_REPO}"
echo "    目标：${AXIOS_PATH}"
echo ""

STATUS=$(curl -sf -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${JFROG_TOKEN}" \
  "${JFROG_URL}/artifactory/${REMOTE_REPO}/${AXIOS_PATH}" 2>/dev/null || echo "000")

if [ "$STATUS" = "200" ]; then
  curl -sf -X DELETE \
    -H "Authorization: Bearer ${JFROG_TOKEN}" \
    "${JFROG_URL}/artifactory/${REMOTE_REPO}/${AXIOS_PATH}" >/dev/null
  echo "  ✅ 缓存已清除：axios@1.7.2"
elif [ "$STATUS" = "404" ]; then
  echo "  ℹ️  缓存中不存在 axios@1.7.2，无需清除"
else
  echo "  ⚠️  无法访问仓库（HTTP ${STATUS}），请检查 JFROG_TOKEN 是否有效" >&2
  exit 1
fi

echo ""
echo "  现在可以运行以下命令测试 Curation 拦截效果："
echo ""
echo "    cd /workspaces/jfrog-workshop/npm-sample"
echo "    rm -rf node_modules package-lock.json"
echo "    npm cache clean --force"
echo "    jf npm install --build-name=${NICKNAME}-npm-sample --build-number=2"
echo ""
echo "  预期结果：安装被 Curation Policy 阻断，提示 axios@1.7.2 不允许下载。"
echo ""
