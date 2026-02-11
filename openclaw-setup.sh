#!/usr/bin/env bash
set -euo pipefail

echo "==> OpenClaw Container Setup"

# Container should already have Node.js and OpenClaw from initial setup
# This script is for any additional configuration

echo "[1/3] Installing Node.js 22..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
  sudo dnf install -y nodejs
fi

echo "[2/3] Installing OpenClaw globally in container..."
if command -v openclaw &> /dev/null; then
  echo "✓ OpenClaw already installed: $(openclaw --version)"
else
  sudo npm install -g openclaw
  echo "✓ OpenClaw installed: $(openclaw --version)"
fi

echo "[3/3] Ensuring git is installed..."
if ! command -v git &> /dev/null; then
  sudo dnf install -y git
fi

# Configure git if not already done
if [ ! -f ~/.gitconfig ]; then
  git config --global user.name "YiSHuA"
  git config --global user.email "yishua@example.com"
  git config --global init.defaultBranch main
fi

echo "==> OpenClaw container setup complete!"
echo ""
echo "Configuration directory: ~/.openclaw"
echo "Agents: $(ls -1 ~/.openclaw/agents 2>/dev/null | wc -l) agents"
echo "Workspace: ~/.openclaw/workspace"
