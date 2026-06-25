#!/bin/bash
# npm-basic module: task verification functions
# npm-basic 模块：任务验证函数
#
# Each function is named verify_<TASK_ID> (hyphens replaced with underscores).
# Called dynamically by check-and-update-progress.sh via: verify_$(echo "$task_id" | tr '-' '_')
# 每个函数命名为 verify_<TASK_ID>（连字符替换为下划线）
# 由 check-and-update-progress.sh 通过 verify_$(echo "$task_id" | tr '-' '_') 动态调用

# Requires: NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf() to be set by the caller
# 依赖调用方设置：NICKNAME, JFROG_URL, JFROG_TOKEN, API, curl_jf()

verify_npm_basic_T1() {
  local s
  s=$(curl_jf -o /dev/null -w "%{http_code}" \
    "${API}/repositories/${NICKNAME}-npm-dev-virtual" 2>/dev/null || echo "000")
  [ "$s" = "200" ]
}

verify_npm_basic_T2() {
  local children
  children=$(curl_jf "${API}/storage/${NICKNAME}-npm-org-remote-cache" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('children',[])))" \
    2>/dev/null || echo "0")
  [ "$children" -gt 0 ]
}
