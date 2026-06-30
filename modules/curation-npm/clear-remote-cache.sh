#!/bin/bash
# Clear the participant's cached axios@1.7.2 from their Artifactory remote repository
# 清除学员个人 Artifactory 远程仓库中的 axios@1.7.2 缓存
# Run before T5 install to ensure the Curation Policy can intercept it
# 在 T5 安装前执行，确保 Curation Policy 能够拦截

set -eu

PROFILE_FILE="${HOME}/.workshop-profile"

if [ ! -f "$PROFILE_FILE" ]; then
  echo "❌ ~/.workshop-profile not found. Please complete registration (T1) first." >&2
  echo "❌ 未找到 ~/.workshop-profile，请先完成注册（T1）" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$PROFILE_FILE"

: "${NICKNAME:?}" "${JFROG_URL:?}" "${JFROG_TOKEN:?}"
JFROG_URL="${JFROG_URL%/}"

REMOTE_REPO="${NICKNAME}-npm-org-remote"
REMOTE_CACHE="${NICKNAME}-npm-org-remote-cache"
AXIOS_PATH="axios/-/axios-1.7.2.tgz"

echo ""
echo ">>> Clearing Artifactory remote repository cache / 清除 Artifactory 远程仓库缓存：${REMOTE_CACHE}"
echo "    Target / 目标：${AXIOS_PATH}"
echo ""

STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  -H "Authorization: Bearer ${JFROG_TOKEN}" \
  "${JFROG_URL}/artifactory/${REMOTE_CACHE}/${AXIOS_PATH}" 2>/dev/null || echo "000")

if [ "$STATUS" = "200" ] || [ "$STATUS" = "204" ]; then
  echo "  ✅ Cache cleared / 缓存已清除：axios@1.7.2"
elif [ "$STATUS" = "404" ]; then
  echo "  ℹ️  axios@1.7.2 not in cache, nothing to clear / 缓存中不存在 axios@1.7.2，无需清除"
else
  echo "  ⚠️  Delete failed (HTTP ${STATUS}). Check if JFROG_TOKEN is valid." >&2
  echo "  ⚠️  删除失败（HTTP ${STATUS}），请检查 JFROG_TOKEN 是否有效" >&2
  exit 1
fi

echo ""
echo "  Now run the following commands to test Curation blocking / 现在可以运行以下命令测试 Curation 拦截效果："
echo ""
echo "    cd /workspaces/jfrog-workshop/modules/curation-npm/sample-project"
echo "    rm -rf node_modules package-lock.json"
echo "    npm cache clean --force"
echo "    jf npm install --build-name=${NICKNAME}-npm-sample --build-number=2"
echo ""
echo "  Expected: install blocked by Curation Policy, axios@1.7.2 not allowed."
echo "  预期结果：安装被 Curation Policy 阻断，提示 axios@1.7.2 不允许下载。"
echo ""
