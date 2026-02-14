#!/bin/bash
PASS=0; FAIL=0

check() {
  local desc=$1 cmd=$2
  if timeout 15 bash -c "$cmd" &>/dev/null 2>&1; then
    echo "  ✅ $desc"; ((PASS++))
  else
    echo "  ❌ $desc"; ((FAIL++))
  fi
}

echo "=== ai-agents verification ==="
check "Container exists" "distrobox list | grep -q 'ai-agents'"
check "opencode installed" "distrobox enter ai-agents -- bash -c 'source /etc/profile.d/ai-agents.sh 2>/dev/null; which opencode || ls ~/.opencode/bin/opencode'"
check "gemini accessible" "distrobox enter ai-agents -- bash -c 'ls ~/.local/node-v22.22.0-linux-x64/bin/gemini 2>/dev/null || which gemini'"
check "qwen installed" "distrobox enter ai-agents -- which qwen"
check "OpenCode config exists" "test -f /var/home/yish/opt-ai-agents/opencode/opencode.json"
check "Gemini config exists" "test -f /var/home/yish/opt-ai-agents/gemini/settings.json"
check "OPENCODE_CONFIG_DIR set" "distrobox enter ai-agents -- bash -c 'source /etc/profile.d/ai-agents.sh 2>/dev/null && test -n \"\$OPENCODE_CONFIG_DIR\"'"
check "LITELLM_BASE_URL set" "distrobox enter ai-agents -- bash -c 'source /etc/profile.d/ai-agents.sh 2>/dev/null && echo \$LITELLM_BASE_URL' | grep -q '4000'"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
