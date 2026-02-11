#!/usr/bin/env bash
set -euo pipefail

echo "==> Cursor IDE Development Container Setup"

# Update system (Ubuntu-based)
echo "==> Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install core dependencies
echo "==> Installing core dependencies..."
sudo apt-get install -y \
  git \
  curl \
  wget \
  unzip \
  build-essential \
  libssl-dev \
  libsqlite3-dev \
  ca-certificates \
  gnupg \
  lsb-release \
  vim \
  nano \
  htop \
  tmux \
  rsync \
  software-properties-common

# Install Node.js 22 LTS (via NodeSource)
echo "==> Installing Node.js 22..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
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

# Install Docker CLI
echo "==> Installing Docker CLI..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce-cli
else
  echo "Docker CLI already installed: $(docker --version)"
fi

# Install GitHub CLI
echo "==> Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y gh
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
mkdir -p ~/workspace/cursor-projects

# Add environment variables to bashrc
echo "==> Configuring environment variables..."
cat >> ~/.bashrc << 'EOFBASHRC'

# Cursor Development Environment
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Node.js
export NODE_OPTIONS="--max-old-space-size=4096"

# Editor
export EDITOR="vim"

# Container identifier
export DISTROBOX_CONTAINER="cursor-dev"

# Prompt customization
export PS1="[\u@\h \W]\$ "
EOFBASHRC

echo "==> Setup complete!"
echo ""
echo "To apply changes, run: source ~/.bashrc"
