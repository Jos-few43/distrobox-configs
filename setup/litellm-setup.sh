#!/usr/bin/env bash
set -euo pipefail

echo "==> LiteLLM Proxy Container Setup"

echo "[1/4] Updating system packages..."
sudo dnf update -y

echo "[2/4] Installing build dependencies..."
sudo dnf install -y \
  git \
  curl \
  wget \
  gcc \
  gcc-c++ \
  make \
  python3 \
  python3-pip \
  python3-devel

echo "[3/4] Installing LiteLLM with proxy support..."
pip install --user 'litellm[proxy]'

echo "[4/4] Verifying installation..."
if command -v litellm &> /dev/null; then
  echo "✓ LiteLLM installed successfully"
  litellm --version
else
  echo "✗ LiteLLM installation failed"
  exit 1
fi

echo ""
echo "==> Setup Complete!"
echo ""
echo "Next steps:"
echo "  1. Copy .env template: cp ~/.litellm/.env.template ~/.litellm/.env"
echo "  2. Add your API keys to ~/.litellm/.env"
echo "  3. Start proxy: litellm --config ~/.litellm/config.yaml"
echo "  4. Access UI: http://localhost:4000/ui"
echo ""
echo "Configuration files:"
echo "  - Config: ~/.litellm/config.yaml"
echo "  - Env vars: ~/.litellm/.env"
echo "  - Docs: ~/.litellm/README.md"
