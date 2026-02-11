#!/usr/bin/env bash
set -euo pipefail

echo "==> Claude Code Development Container Setup"

# Update system
echo "==> Updating system packages..."
sudo dnf update -y

# Install core dependencies
echo "==> Installing core dependencies..."
sudo dnf install -y \
  git \
  curl \
  wget \
  unzip \
  gcc \
  g++ \
  make \
  openssl-devel \
  sqlite-devel \
  ca-certificates \
  gnupg \
  python3 \
  python3-pip \
  vim \
  nano \
  htop \
  tmux \
  rsync

# Install Node.js 22 LTS
echo "==> Installing Node.js 22..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
  sudo dnf install -y nodejs
else
  echo "Node.js already installed: $(node --version)"
fi

# Install pnpm
echo "==> Installing pnpm..."
if ! command -v pnpm &> /dev/null; then
  npm install -g pnpm
else
  echo "pnpm already installed: $(pnpm --version)"
fi

# Install global TypeScript tools
echo "==> Installing TypeScript toolchain..."
npm install -g typescript tsx @types/node

# Install Python packages (Claude Code may use Python tooling)
echo "==> Installing Python packages..."
pip3 install --user --upgrade pip
pip3 install --user poetry pylint black mypy

# Install GitHub CLI
echo "==> Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
  sudo dnf install -y gh
else
  echo "GitHub CLI already installed: $(gh --version | head -n1)"
fi

# Configure Git
echo "==> Configuring Git..."
if [ -f ~/.gitconfig ]; then
  echo "Git config already exists, preserving..."
else
  GIT_NAME=$(git config --global user.name 2>/dev/null || echo "YiSHuA")
  GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "yishua@example.com")

  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.editor vim

  echo "Git configured: $GIT_NAME <$GIT_EMAIL>"
fi

# Create workspace directory
mkdir -p ~/workspace
mkdir -p ~/workspace/claude-projects

# Add environment variables to bashrc
echo "==> Configuring environment variables..."
cat >> ~/.bashrc << 'EOFBASHRC'

# Claude Code Development Environment
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Python
export PATH="$HOME/.local/bin:$PATH"

# Node.js
export NODE_OPTIONS="--max-old-space-size=4096"

# Editor
export EDITOR="vim"

# Container identifier
export DISTROBOX_CONTAINER="claude-dev"

# Prompt customization
export PS1="[\u@\h \W]\$ "
EOFBASHRC

echo "==> Setup complete!"
echo ""
echo "To apply changes, run: source ~/.bashrc"
