#!/usr/bin/env bash
set -euo pipefail

echo "==> LiteLLM Proxy Health Check"

# Check if container is running (disable pipefail to avoid SIGPIPE from grep -q)
set +o pipefail
if ! distrobox list --no-color | grep -q "litellm-dev.*Up"; then
  echo "ERROR: litellm-dev container is not running"
  echo ""
  echo "To start the container, run:"
  echo "  distrobox enter litellm-dev"
  exit 1
fi
set -o pipefail

echo "  [✓] Container is running"
echo ""

# Enter container and run checks
distrobox enter litellm-dev -- bash -c '
  set -e

  echo "==> LiteLLM Installation"

  if command -v litellm &>/dev/null; then
    LITELLM_VERSION=$(litellm --version 2>&1 | head -1 || echo "unknown")
    echo "  [✓] LiteLLM installed: $LITELLM_VERSION"
  else
    echo "  [✗] LiteLLM not installed"
    exit 1
  fi

  echo ""
  echo "==> Configuration Files"

  if [ -f ~/.litellm/config.yaml ]; then
    echo "  [✓] Config file exists: ~/.litellm/config.yaml"
    MODEL_COUNT=$(grep "model_name:" ~/.litellm/config.yaml | wc -l)
    echo "  [✓] Configured models: $MODEL_COUNT"
  else
    echo "  [✗] Config file missing"
  fi

  if [ -f ~/.litellm/.env ]; then
    echo "  [✓] Environment file exists: ~/.litellm/.env"
  else
    echo "  [✗] Environment file missing"
  fi

  if [ -f ~/.litellm/README.md ]; then
    echo "  [✓] Documentation exists"
  else
    echo "  [!] README missing (non-critical)"
  fi

  echo ""
  echo "==> API Keys Configuration"

  if grep -q "GEMINI_API_KEY=$" ~/.litellm/.env 2>/dev/null; then
    echo "  [!] GEMINI_API_KEY not configured"
  elif grep -q "GEMINI_API_KEY=" ~/.litellm/.env 2>/dev/null; then
    echo "  [✓] GEMINI_API_KEY configured"
  fi

  if grep -q "OPENCODE_API_KEY=$" ~/.litellm/.env 2>/dev/null; then
    echo "  [!] OPENCODE_API_KEY not configured"
  elif grep -q "OPENCODE_API_KEY=" ~/.litellm/.env 2>/dev/null; then
    echo "  [✓] OPENCODE_API_KEY configured"
  fi

  if grep -q "OPENROUTER_API_KEY=$" ~/.litellm/.env 2>/dev/null; then
    echo "  [!] OPENROUTER_API_KEY not configured"
  elif grep -q "OPENROUTER_API_KEY=" ~/.litellm/.env 2>/dev/null; then
    echo "  [✓] OPENROUTER_API_KEY configured"
  fi

  if grep -q "LITELLM_MASTER_KEY=sk-1234567890abcdef" ~/.litellm/.env 2>/dev/null; then
    echo "  [!] LITELLM_MASTER_KEY using default (change recommended)"
  else
    echo "  [✓] LITELLM_MASTER_KEY configured"
  fi

  echo ""
  echo "==> Proxy Status"

  if curl -s http://localhost:4000/health &>/dev/null; then
    echo "  [✓] Proxy is running on http://localhost:4000"
    echo "  [✓] UI available at http://localhost:4000/ui"
  else
    echo "  [!] Proxy not running"
    echo "  [!] Start with: litellm --config ~/.litellm/config.yaml"
  fi
'

echo ""
echo "==> Health check complete"
