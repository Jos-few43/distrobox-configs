# Distrobox Quick Reference

Fast command reference for managing coding agent containers.

## OpenCode Container

### Create and Setup

```bash
# Create container
distrobox create \
  --name opencode-dev \
  --image registry.fedoraproject.org/fedora:43 \
  --home /var/home/yish \
  --volume /var/home/yish:/var/home/yish:rw \
  --volume /run/host/etc/localtime:/etc/localtime:ro \
  --additional-flags "--network host" \
  --additional-flags "--security-opt label=disable" \
  --additional-flags "--ipc host" \
  --init

# Enter and setup
distrobox enter opencode-dev
bash ~/distrobox-configs/opencode-setup.sh
```

### Daily Usage

```bash
# Enter container
distrobox enter opencode-dev

# Run health check (from host)
bash ~/distrobox-configs/opencode-healthcheck.sh

# Run commands without entering
distrobox enter opencode-dev -- node --version
distrobox enter opencode-dev -- pnpm dev
```

### Maintenance

```bash
# Update packages
distrobox enter opencode-dev -- sudo dnf update -y

# Stop container
distrobox stop opencode-dev

# Remove container
distrobox rm opencode-dev

# Recreate (nuclear option)
distrobox rm -f opencode-dev && \
  distrobox create --name opencode-dev [...]
```

## All Containers

### List

```bash
# Show all containers
distrobox list

# Show running containers
distrobox list | grep "Up"
```

### Bulk Operations

```bash
# Stop all containers
distrobox stop --all

# Update all containers
for container in $(distrobox list --no-color | tail -n +2 | awk '{print $2}'); do
  echo "Updating $container..."
  distrobox enter "$container" -- sudo dnf update -y
done
```

### Cleanup

```bash
# Clean unused images
podman image prune -f

# Clean all (nuclear)
podman system prune -af

# Show storage usage
podman system df
```

## Common Issues

### Fix: Container won't start

```bash
podman logs opencode-dev
distrobox rm -f opencode-dev
# Recreate container
```

### Fix: Permission denied

```bash
# Inside container
sudo chown -R $USER:$USER ~/.opencode

# On host (SELinux)
sudo chcon -R -t container_file_t /var/home/yish
```

### Fix: Network issues

```bash
# Test DNS
distrobox enter opencode-dev -- nslookup npmjs.org

# Test connectivity
distrobox enter opencode-dev -- curl -I https://registry.npmjs.org
```

## Environment Variables

```bash
# Inside container, add to ~/.bashrc
export OPENCODE_HOME="$HOME/.opencode"
export PATH="$OPENCODE_HOME/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
```

## Shortcuts

Create these aliases on the host in `~/.bashrc`:

```bash
# Container shortcuts
alias oc-enter='distrobox enter opencode-dev'
alias oc-check='bash ~/distrobox-configs/opencode-healthcheck.sh'
alias oc-update='distrobox enter opencode-dev -- sudo dnf update -y'
alias oc-clean='distrobox enter opencode-dev -- "pnpm store prune && npm cache clean --force"'

# Quick command execution
alias oc-run='distrobox enter opencode-dev --'
alias oc-node='distrobox enter opencode-dev -- node'
alias oc-pnpm='distrobox enter opencode-dev -- pnpm'
alias oc-bun='distrobox enter opencode-dev -- bun'
```

Then use:

```bash
oc-enter           # Enter container
oc-check           # Health check
oc-node --version  # Run node
oc-pnpm install    # Run pnpm
```
