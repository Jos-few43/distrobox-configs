#!/usr/bin/env bash
set -euo pipefail

echo "==> OpenCode Development Container Setup"

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
  lsb-release \
  vim \
  nano \
  htop \
  tmux \
  rsync \
  tar \
  gzip \
  bzip2 \
  xz

# Install Node.js 22 LTS
echo "==> Installing Node.js 22..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
  sudo dnf install -y nodejs
else
  echo "Node.js already installed: $(node --version)"
fi

# Install Bun
echo "==> Installing Bun..."
if ! command -v bun &> /dev/null; then
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.bashrc
  echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.bashrc
else
  echo "Bun already installed: $(bun --version)"
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

# Install Docker CLI (for docker-based workflows)
echo "==> Installing Docker CLI..."
if ! command -v docker &> /dev/null; then
  sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null || true
  sudo dnf install -y docker-ce-cli || {
    echo "Warning: Could not install Docker CLI from official repo, trying Fedora repo..."
    sudo dnf install -y docker || echo "Docker CLI installation failed, continuing..."
  }
else
  echo "Docker CLI already installed: $(docker --version)"
fi

# Install GitHub CLI
echo "==> Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
  sudo dnf install -y gh
else
  echo "GitHub CLI already installed: $(gh --version | head -n1)"
fi

# Configure Git (inherit from host or set defaults)
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

# Set up SSH agent forwarding
echo "==> Configuring SSH..."
if [ ! -S "${SSH_AUTH_SOCK:-}" ]; then
  eval "$(ssh-agent -s)" 2>/dev/null || true
  echo 'eval "$(ssh-agent -s)" 2>/dev/null' >> ~/.bashrc
fi

# Install OpenCode CLI (if not present)
echo "==> Checking OpenCode installation..."
if [ ! -d ~/.opencode ]; then
  echo "OpenCode not found in ~/.opencode"
  echo "To install OpenCode, run: npm install -g @opencode/cli"
else
  echo "OpenCode found at ~/.opencode"
  if [ -f ~/.opencode/bin/opencode ]; then
    echo "OpenCode version: $(~/.opencode/bin/opencode --version 2>/dev/null || echo 'unknown')"
  fi
fi

# Create workspace directory
mkdir -p ~/workspace
mkdir -p ~/workspace/opencode-projects

# Add environment variables to bashrc
echo "==> Configuring environment variables..."
cat >> ~/.bashrc << 'EOFBASHRC'

# OpenCode Development Environment
export OPENCODE_HOME="$HOME/.opencode"
export PATH="$OPENCODE_HOME/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Node.js
export NODE_OPTIONS="--max-old-space-size=4096"

# Editor
export EDITOR="vim"

# Container identifier
export DISTROBOX_CONTAINER="opencode-dev"

# Prompt customization
export PS1="[\u@\h \W]\$ "
EOFBASHRC

echo "==> Setup complete!"
echo ""
echo "To apply changes, run: source ~/.bashrc"
echo "Or exit and re-enter the container: exit && distrobox enter opencode-dev"
