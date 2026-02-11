#!/usr/bin/env bash
set -euo pipefail

echo "==> AI CLI Tools Container Setup"

echo "[1/5] Updating system packages..."
sudo dnf update -y

echo "[2/5] Installing build dependencies..."
sudo dnf install -y \
  git \
  curl \
  wget \
  gcc \
  gcc-c++ \
  make

echo "[3/5] Installing Node.js 22..."
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo dnf install -y nodejs

echo "[4/5] Installing AI CLI tools globally in container..."
sudo npm install -g \
  @qwen-code/qwen-code \
  @google/gemini-cli

echo "[5/5] Verifying installations..."
echo ""
echo "==> Qwen Code:"
if command -v qwen &> /dev/null; then
  echo "✓ Qwen Code installed successfully"
  qwen --version
else
  echo "✗ Qwen Code installation failed"
  exit 1
fi

echo ""
echo "==> Gemini CLI:"
if command -v gemini &> /dev/null; then
  echo "✓ Gemini CLI installed successfully"
  gemini --version
else
  echo "✗ Gemini CLI installation failed"
  exit 1
fi

echo ""
echo "==> Setup Complete!"
echo ""
echo "Package installation:"
echo "  Installed to: /usr/lib/node_modules (system-wide)"
echo "  Isolated from host: YES"
echo ""
echo "Available commands:"
echo "  qwen      - Qwen Code interactive CLI"
echo "  gemini    - Google Gemini CLI"
echo ""
echo "Configuration locations:"
echo "  Qwen:   ~/.config/qwen-code/ (shared with host)"
echo "  Gemini: ~/.config/gemini-cli/ (shared with host)"
echo ""
echo "Quick start:"
echo "  qwen 'explain this code'      # One-shot query"
echo "  qwen                           # Interactive mode"
echo "  gemini 'write a function'     # One-shot query"
echo "  gemini                         # Interactive mode"
