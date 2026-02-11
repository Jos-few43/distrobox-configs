#!/usr/bin/env bash
set -euo pipefail

echo "==> OpenClaw Container Setup"

# Container should already have Node.js and OpenClaw from initial setup
# This script is for any additional configuration

echo "==> Verifying OpenClaw installation..."
if command -v openclaw &> /dev/null; then
  echo "OpenClaw version: $(openclaw --version)"
else
  echo "Installing OpenClaw..."
  npm install -g openclaw
fi

# Ensure git is installed (needed for OpenClaw)
if ! command -v git &> /dev/null; then
  echo "==> Installing git..."
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
