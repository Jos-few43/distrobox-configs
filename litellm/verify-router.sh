#!/usr/bin/env bash
# verify-router.sh — checks all prerequisites for litellm-router setup

PASS=0
FAIL=0

check() {
    local desc="$1"
    shift
    if "$@" &>/dev/null 2>&1; then
        echo "✅ $desc"
        PASS=$((PASS + 1))
    else
        echo "❌ $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== litellm-router prerequisite checks ==="
echo ""

# 1. Container litellm-router exists
check "Container 'litellm-router' exists" \
    bash -c "distrobox list | grep -q 'litellm-router'"

# 2. haproxy is installed inside the container
# Uses timeout to avoid hanging if container doesn't exist
check "haproxy installed in litellm-router" \
    timeout 10 distrobox enter litellm-router -- which haproxy

# 3. ~/litellm-router/haproxy.cfg exists
check "~/litellm-router/haproxy.cfg exists" \
    test -f "$HOME/litellm-router/haproxy.cfg"

# 4. promote.sh exists
check "~/distrobox-configs/litellm/promote.sh exists" \
    test -f "$HOME/distrobox-configs/litellm/promote.sh"

# 5. promote.sh is executable
check "~/distrobox-configs/litellm/promote.sh is executable" \
    test -x "$HOME/distrobox-configs/litellm/promote.sh"

# 6. status.sh is executable
check "~/distrobox-configs/litellm/status.sh is executable" \
    test -x "$HOME/distrobox-configs/litellm/status.sh"

# 7. rollback.sh is executable
check "~/distrobox-configs/litellm/rollback.sh is executable" \
    test -x "$HOME/distrobox-configs/litellm/rollback.sh"

# 8. Port 4000 is listening
check "Port 4000 is listening" \
    bash -c "ss -tlnp | grep -q ':4000'"

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -eq 0 ]; then
    exit 0
else
    exit 1
fi
