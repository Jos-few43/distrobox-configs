#!/usr/bin/env bash
set -euo pipefail

echo "==> OpenCode Container Health Check"

# Check if container is running
if ! distrobox list | grep -q "opencode-dev.*Up"; then
  echo "ERROR: opencode-dev container is not running"
  echo ""
  echo "To start the container, run:"
  echo "  distrobox enter opencode-dev"
  exit 1
fi

echo "  [✓] Container is running"
echo ""

# Enter container and run checks
distrobox enter opencode-dev -- bash -c '
  set -e

  echo "==> Tool Availability"

  if command -v node &>/dev/null; then
    echo "  [✓] Node.js $(node --version)"
  else
    echo "  [✗] Node.js missing"
  fi

  if command -v bun &>/dev/null; then
    echo "  [✓] Bun $(bun --version)"
  else
    echo "  [✗] Bun missing"
  fi

  if command -v pnpm &>/dev/null; then
    echo "  [✓] pnpm $(pnpm --version)"
  else
    echo "  [✗] pnpm missing"
  fi

  if command -v git &>/dev/null; then
    echo "  [✓] Git $(git --version | cut -d" " -f3)"
  else
    echo "  [✗] Git missing"
  fi

  if command -v gh &>/dev/null; then
    echo "  [✓] GitHub CLI $(gh --version | head -n1 | cut -d" " -f3)"
  else
    echo "  [✗] GitHub CLI missing"
  fi

  if command -v docker &>/dev/null; then
    echo "  [✓] Docker CLI $(docker --version | cut -d" " -f3 | tr -d ",")"
  else
    echo "  [✗] Docker CLI missing"
  fi

  echo ""
  echo "==> OpenCode Installation"

  if [ -d ~/.opencode ]; then
    echo "  [✓] OpenCode directory exists"

    if [ -f ~/.opencode/bin/opencode ]; then
      OC_VERSION=$(~/.opencode/bin/opencode --version 2>/dev/null || echo "unknown")
      echo "  [✓] OpenCode CLI available (version: $OC_VERSION)"
    else
      echo "  [✗] OpenCode CLI not found at ~/.opencode/bin/opencode"
    fi
  else
    echo "  [✗] OpenCode directory missing at ~/.opencode"
  fi

  echo ""
  echo "==> File System Permissions"

  if [ -w ~ ]; then
    echo "  [✓] Home directory is writable"
  else
    echo "  [✗] Home directory is NOT writable"
  fi

  if touch ~/test-healthcheck-write 2>/dev/null; then
    rm ~/test-healthcheck-write
    echo "  [✓] Can create files in home directory"
  else
    echo "  [✗] Cannot create files in home directory"
  fi

  echo ""
  echo "==> Network Connectivity"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://registry.npmjs.org 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ]; then
    echo "  [✓] npm registry reachable (HTTP $HTTP_CODE)"
  else
    echo "  [✗] npm registry unreachable (HTTP $HTTP_CODE)"
  fi

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://github.com 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ]; then
    echo "  [✓] GitHub reachable (HTTP $HTTP_CODE)"
  else
    echo "  [✗] GitHub unreachable (HTTP $HTTP_CODE)"
  fi

  if nslookup npmjs.org &>/dev/null; then
    echo "  [✓] DNS resolution working"
  else
    echo "  [✗] DNS resolution failing"
  fi

  echo ""
  echo "==> Git Configuration"

  GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
  GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

  if [ -n "$GIT_NAME" ]; then
    echo "  [✓] Git user.name: $GIT_NAME"
  else
    echo "  [✗] Git user.name not configured"
  fi

  if [ -n "$GIT_EMAIL" ]; then
    echo "  [✓] Git user.email: $GIT_EMAIL"
  else
    echo "  [✗] Git user.email not configured"
  fi

  echo ""
  echo "==> SSH Configuration"

  if [ -n "${SSH_AUTH_SOCK:-}" ]; then
    echo "  [✓] SSH_AUTH_SOCK is set: $SSH_AUTH_SOCK"
  else
    echo "  [✗] SSH_AUTH_SOCK not set"
  fi

  if ssh -T git@github.com 2>&1 | grep -qi "success\|authenticated"; then
    echo "  [✓] GitHub SSH authentication working"
  else
    echo "  [!] GitHub SSH authentication failed (this is OK if you use HTTPS)"
  fi

  echo ""
  echo "==> Workspace Directories"

  if [ -d ~/workspace ]; then
    echo "  [✓] ~/workspace exists"
  else
    echo "  [!] ~/workspace missing (will be created when needed)"
  fi

  if [ -d ~/workspace/opencode-projects ]; then
    echo "  [✓] ~/workspace/opencode-projects exists"
  else
    echo "  [!] ~/workspace/opencode-projects missing (will be created when needed)"
  fi
'

echo ""
echo "==> Health check complete"
