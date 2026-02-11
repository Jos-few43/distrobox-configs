#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
  cat << EOF
Distrobox Container Manager for Coding Agents

Usage: $0 <command> [agent]

Commands:
  create <agent>   Create a new container for the specified agent
  setup <agent>    Run initial setup in existing container
  enter <agent>    Enter the container shell
  check <agent>    Run health check on container
  update <agent>   Update packages in container
  stop <agent>     Stop the container
  remove <agent>   Remove the container
  list             List all containers
  help             Show this help message

Agents:
  opencode         OpenCode AI agent (Fedora 43)
  openclaw         OpenClaw AI agent (Fedora 43)
  litellm          LiteLLM API proxy (Fedora 43)
  ai-cli-tools     AI CLI tools (Qwen Code, Gemini) (Fedora 43)
  cursor           Cursor IDE (Ubuntu 24.04)
  claude           Claude Code (Fedora 43)
  windsurf         Windsurf (Fedora 43)

Examples:
  $0 create opencode     # Create OpenCode container
  $0 setup opencode      # Run setup script in container
  $0 check opencode      # Run health check
  $0 enter opencode      # Enter container shell
  $0 list                # List all containers
EOF
}

create_opencode() {
  info "Creating OpenCode development container..."

  distrobox create \
    --name opencode-dev \
    --image registry.fedoraproject.org/fedora:43 \
    --yes

  success "OpenCode container created!"
  info "Next steps:"
  echo "  1. Run automated setup: $0 setup opencode"
  echo "  2. Run health check: $0 check opencode"
  echo "  3. Enter container: $0 enter opencode"
}

create_openclaw() {
  info "Creating OpenClaw AI agent container..."

  distrobox create \
    --name openclaw-dev \
    --image registry.fedoraproject.org/fedora:43 \
    --yes

  success "OpenClaw container created!"
  info "Next steps:"
  echo "  1. Run automated setup: $0 setup openclaw"
  echo "  2. Run health check: $0 check openclaw"
  echo "  3. Enter container: $0 enter openclaw"
}

create_litellm() {
  info "Creating LiteLLM proxy container..."

  distrobox create \
    --name litellm-proxy \
    --image registry.fedoraproject.org/fedora:43 \
    --yes

  success "LiteLLM container created!"
  info "Next steps:"
  echo "  1. Run automated setup: $0 setup litellm"
  echo "  2. Configure API keys: cp ~/.litellm/.env.template ~/.litellm/.env"
  echo "  3. Start proxy: distrobox enter litellm-proxy -- litellm --config ~/.litellm/config.yaml"
  echo "  4. Access UI: http://localhost:4000/ui"
}

create_ai_cli_tools() {
  info "Creating AI CLI tools container..."

  distrobox create \
    --name ai-cli-tools-dev \
    --image registry.fedoraproject.org/fedora:43 \
    --yes

  success "AI CLI tools container created!"
  info "Next steps:"
  echo "  1. Run automated setup: $0 setup ai-cli-tools"
  echo "  2. Enter container: $0 enter ai-cli-tools"
  echo "  3. Use tools: qwen, gemini"
}

create_cursor() {
  info "Creating Cursor IDE development container..."

  distrobox create \
    --name cursor-dev \
    --image docker.io/library/ubuntu:24.04 \
    --yes

  success "Cursor container created!"
  info "Next steps:"
  echo "  1. Run setup: $0 setup cursor"
  echo "  2. Enter container: $0 enter cursor"
}

create_claude() {
  info "Creating Claude Code development container..."

  distrobox create \
    --name claude-dev \
    --image registry.fedoraproject.org/fedora:43 \
    --yes

  success "Claude Code container created!"
  info "Next steps:"
  echo "  1. Run setup: $0 setup claude"
  echo "  2. Enter container: $0 enter claude"
}

create_windsurf() {
  info "Creating Windsurf development container..."

  distrobox create \
    --name windsurf-dev \
    --image registry.fedoraproject.org/fedora:43 \
    --yes

  success "Windsurf container created!"
  info "Next steps:"
  echo "  1. Create setup script for windsurf if needed"
  echo "  2. Enter container: $0 enter windsurf"
}

setup_agent() {
  local agent=$1
  local container="${agent}-dev"
  local setup_script="$SCRIPT_DIR/../setup/${agent}-setup.sh"

  if [ ! -f "$setup_script" ]; then
    error "Setup script not found: $setup_script"
    return 1
  fi

  info "Running setup for ${agent}..."
  distrobox enter "$container" -- bash "$setup_script"
  success "Setup complete for ${agent}!"
}

enter_agent() {
  local agent=$1
  local container="${agent}-dev"

  info "Entering ${agent} container..."
  distrobox enter "$container"
}

check_agent() {
  local agent=$1

  if [ "$agent" = "opencode" ]; then
    if [ -f "$SCRIPT_DIR/opencode-healthcheck.sh" ]; then
      bash "$SCRIPT_DIR/opencode-healthcheck.sh"
    else
      error "Health check script not found for opencode"
      return 1
    fi
  else
    warning "Health check not yet implemented for ${agent}"
    info "Checking if container is running..."
    distrobox list | grep "${agent}-dev" || error "Container ${agent}-dev not found"
  fi
}

update_agent() {
  local agent=$1
  local container="${agent}-dev"

  info "Updating packages in ${agent} container..."

  # Detect package manager based on container
  if distrobox enter "$container" -- command -v dnf &>/dev/null; then
    distrobox enter "$container" -- sudo dnf update -y
  elif distrobox enter "$container" -- command -v apt-get &>/dev/null; then
    distrobox enter "$container" -- sudo apt-get update
    distrobox enter "$container" -- sudo apt-get upgrade -y
  else
    error "Unknown package manager in container ${container}"
    return 1
  fi

  success "Packages updated in ${agent} container!"
}

stop_agent() {
  local agent=$1
  local container="${agent}-dev"

  info "Stopping ${agent} container..."
  distrobox stop "$container"
  success "Container ${container} stopped!"
}

remove_agent() {
  local agent=$1
  local container="${agent}-dev"

  warning "This will permanently remove the ${agent} container!"
  read -p "Are you sure? (yes/no): " confirm

  if [ "$confirm" = "yes" ]; then
    info "Removing ${agent} container..."
    distrobox rm -f "$container"
    success "Container ${container} removed!"
  else
    info "Removal cancelled."
  fi
}

list_containers() {
  info "Listing all distrobox containers..."
  distrobox list
}

# Main command dispatcher
case "${1:-}" in
  create)
    agent="${2:-}"
    case "$agent" in
      opencode) create_opencode ;;
      openclaw) create_openclaw ;;
      litellm) create_litellm ;;
      ai-cli-tools) create_ai_cli_tools ;;
      cursor) create_cursor ;;
      claude) create_claude ;;
      windsurf) create_windsurf ;;
      *)
        error "Unknown agent: $agent"
        echo "Valid agents: opencode, openclaw, litellm, ai-cli-tools, cursor, claude, windsurf"
        exit 1
        ;;
    esac
    ;;

  setup)
    agent="${2:-}"
    if [ -z "$agent" ]; then
      error "Please specify an agent"
      exit 1
    fi
    setup_agent "$agent"
    ;;

  enter)
    agent="${2:-}"
    if [ -z "$agent" ]; then
      error "Please specify an agent"
      exit 1
    fi
    enter_agent "$agent"
    ;;

  check)
    agent="${2:-}"
    if [ -z "$agent" ]; then
      error "Please specify an agent"
      exit 1
    fi
    check_agent "$agent"
    ;;

  update)
    agent="${2:-}"
    if [ -z "$agent" ]; then
      error "Please specify an agent"
      exit 1
    fi
    update_agent "$agent"
    ;;

  stop)
    agent="${2:-}"
    if [ -z "$agent" ]; then
      error "Please specify an agent"
      exit 1
    fi
    stop_agent "$agent"
    ;;

  remove)
    agent="${2:-}"
    if [ -z "$agent" ]; then
      error "Please specify an agent"
      exit 1
    fi
    remove_agent "$agent"
    ;;

  list)
    list_containers
    ;;

  help|--help|-h)
    usage
    ;;

  *)
    error "Unknown command: ${1:-}"
    echo ""
    usage
    exit 1
    ;;
esac
