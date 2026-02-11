# Distrobox Configurations for Coding Agents

This directory contains reproducible container configurations for isolated development environments on Bazzite (immutable Fedora atomic).

## Quick Start

### 1. Create OpenCode Container

```bash
./manage.sh create opencode
```

### 2. Enter and Setup

```bash
./manage.sh enter opencode
# Inside container:
bash ~/distrobox-configs/opencode-setup.sh
```

### 3. Verify Installation

```bash
# From host:
./manage.sh check opencode
```

## Directory Structure

```
distrobox-configs/
├── README.md                    # This file
├── manage.sh                    # Container management wrapper script
├── quick-reference.md           # Fast command reference
│
├── opencode-setup.sh            # OpenCode container setup script (Fedora)
├── opencode-healthcheck.sh      # OpenCode health check script
│
├── cursor-setup.sh              # Cursor IDE setup script (Ubuntu)
├── claude-setup.sh              # Claude Code setup script (Fedora)
│
└── windsurf-setup.sh            # (TODO) Windsurf setup script
```

## Management Commands

Use the `manage.sh` wrapper for all operations:

```bash
# Create containers
./manage.sh create opencode
./manage.sh create cursor
./manage.sh create claude

# Enter containers
./manage.sh enter opencode
./manage.sh enter cursor

# Run setup (inside container)
./manage.sh setup opencode

# Health checks
./manage.sh check opencode

# Update packages
./manage.sh update opencode

# Stop containers
./manage.sh stop opencode

# Remove containers
./manage.sh remove opencode

# List all containers
./manage.sh list
```

## Container Specifications

### OpenCode (`opencode-dev`)

- **Base Image**: Fedora 43
- **Purpose**: OpenCode AI agent development
- **Tools**: Node.js 22, Bun, pnpm, TypeScript, Docker CLI, GitHub CLI
- **Workspace**: `~/workspace/opencode-projects`
- **Setup Script**: `opencode-setup.sh`
- **Health Check**: `opencode-healthcheck.sh`

### Cursor (`cursor-dev`)

- **Base Image**: Ubuntu 24.04
- **Purpose**: Cursor IDE development environment
- **Tools**: Node.js 22, pnpm, TypeScript, Docker CLI, GitHub CLI
- **Workspace**: `~/workspace/cursor-projects`
- **Setup Script**: `cursor-setup.sh`

### Claude Code (`claude-dev`)

- **Base Image**: Fedora 43
- **Purpose**: Claude Code agent development
- **Tools**: Node.js 22, pnpm, TypeScript, Python 3, Poetry, GitHub CLI
- **Workspace**: `~/workspace/claude-projects`
- **Setup Script**: `claude-setup.sh`

### Windsurf (`windsurf-dev`)

- **Base Image**: Fedora 43
- **Purpose**: Windsurf AI agent development
- **Tools**: TBD
- **Workspace**: `~/workspace/windsurf-projects`
- **Setup Script**: TODO

## Common Configurations

All containers share:

- **Home Mount**: `/var/home/yish:/var/home/yish:rw` (full access)
- **Network**: `--network host` (direct host networking)
- **IPC**: `--ipc host` (shared IPC namespace)
- **Security**: `--security-opt label=disable` (SELinux label disabled)
- **Init**: `--init` (proper PID 1 process)

## Files Overview

### `manage.sh`

Central management script with color-coded output:

- Creates containers with proper flags
- Runs setup scripts
- Enters containers
- Performs health checks
- Updates packages
- Stops/removes containers

### Setup Scripts

Each `*-setup.sh` script:

1. Updates system packages
2. Installs development tools (Node.js, Git, etc.)
3. Configures Git with user identity
4. Sets up environment variables
5. Creates workspace directories
6. Adds configuration to `~/.bashrc`

**Important**: Run setup scripts **inside** the container:

```bash
distrobox enter opencode-dev
bash ~/distrobox-configs/opencode-setup.sh
```

### Health Check Scripts

`opencode-healthcheck.sh` verifies:

- Container is running
- Required tools are installed (Node.js, Bun, pnpm, Git, etc.)
- OpenCode installation is present
- File system permissions are correct
- Network connectivity works (npm registry, GitHub)
- Git is configured
- SSH authentication works
- Workspace directories exist

Run from the **host**:

```bash
bash ~/distrobox-configs/opencode-healthcheck.sh
```

### `quick-reference.md`

Fast command reference with:

- Container creation commands
- Daily usage patterns
- Maintenance operations
- Common issues and fixes
- Shell aliases for convenience

## Host Aliases (Optional)

Add to `~/.bashrc` on the host:

```bash
# OpenCode shortcuts
alias oc-enter='distrobox enter opencode-dev'
alias oc-check='bash ~/distrobox-configs/opencode-healthcheck.sh'
alias oc-manage='bash ~/distrobox-configs/manage.sh'

# Cursor shortcuts
alias cursor-enter='distrobox enter cursor-dev'
alias cursor-manage='bash ~/distrobox-configs/manage.sh'

# Claude shortcuts
alias claude-enter='distrobox enter claude-dev'
alias claude-manage='bash ~/distrobox-configs/manage.sh'
```

Then use:

```bash
oc-enter          # Enter OpenCode container
oc-check          # Run health check
oc-manage list    # List containers
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
podman logs opencode-dev

# Recreate container
./manage.sh remove opencode
./manage.sh create opencode
```

### Permission Issues

```bash
# Inside container
sudo chown -R $USER:$USER ~/.opencode

# On host (SELinux)
sudo chcon -R -t container_file_t /var/home/yish
```

### Network Issues

```bash
# Test inside container
distrobox enter opencode-dev -- curl -I https://registry.npmjs.org
distrobox enter opencode-dev -- nslookup npmjs.org

# Check firewall on host
sudo firewall-cmd --list-all
```

### Storage Cleanup

```bash
# Clean Podman storage
podman system prune -af

# Clean npm/pnpm caches inside container
distrobox enter opencode-dev -- pnpm store prune
distrobox enter opencode-dev -- npm cache clean --force
```

## Adding New Agents

To add support for a new coding agent:

1. Create setup script: `<agent>-setup.sh`
2. Add container creation function in `manage.sh`
3. Test container creation and setup
4. Document in this README
5. Update `quick-reference.md` with new commands

**Template structure**:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> <Agent Name> Development Container Setup"

# Update system (choose package manager)
sudo dnf update -y  # Fedora/RHEL
# OR
sudo apt-get update && sudo apt-get upgrade -y  # Debian/Ubuntu

# Install dependencies
# ...

# Configure environment
# ...

# Create workspace
mkdir -p ~/workspace/<agent>-projects

echo "==> Setup complete!"
```

## Best Practices

1. **Always run setup scripts after creating containers**
2. **Use `manage.sh` for consistent operations**
3. **Run health checks after setup to verify installation**
4. **Keep containers updated with `manage.sh update <agent>`**
5. **Use separate containers for different agents to avoid conflicts**
6. **Back up container configurations before major changes**
7. **Document agent-specific requirements in setup scripts**

## References

- [Main Deployment Guide](../DISTROBOX-DEPLOY.md)
- [Quick Reference](./quick-reference.md)
- [Distrobox Documentation](https://distrobox.it/)
- [Bazzite Documentation](https://universal-blue.org/images/bazzite/)

## Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Run health checks: `./manage.sh check <agent>`
3. Review container logs: `podman logs <container-name>`
4. Consult [Quick Reference](./quick-reference.md)
