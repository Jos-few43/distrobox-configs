# distrobox-templates

A comprehensive templating system for creating OS containers with modifier flags (minimal, dev, pentest). Supports containerized environments via distrobox and NixOS VMs.

## Features

- **6 Base OS Templates**: Arch, Fedora, Debian, Ubuntu, Alpine, Kali Linux
- **Modifier Flags**: Combine `--minimal`, `--dev`, `--pentest` as needed
- **Dry-Run Mode**: Preview changes before creating
- **NixOS VM Support**: Full VM creation for NixOS (separate from containers)
- **Export/Import**: Save containers as portable images
- **Qubes-Style Minimal**: Strip docs, locales, timezone data for 20-50% size reduction

## Installation

```bash
cd ~
git clone <repo-url> distrobox-configs
# Or use the directory you already have
cd distrobox-configs

# Make CLI executable
chmod +x bin/distrobox-template

# Add to PATH (optional)
echo 'export PATH="$HOME/distrobox-configs/bin:$PATH"' >> ~/.bashrc
```

## Quick Start

```bash
# Create a basic Arch container
distrobox-template create arch

# Create minimal Arch with dev tools
distrobox-template create arch --minimal --dev

# Preview what would be created (dry-run)
distrobox-template create arch --minimal --dev --dry-run

# Create Kali with pentest tools
distrobox-template create kali --pentest

# List available OS templates
distrobox-template list
```

## Available OS Templates

| OS | Image | Size (Base) | Notes |
|-----|-------|-------------|-------|
| `arch` | ghcr.io/archlinux/archlinux:latest | ~500MB | Rolling release, AUR support |
| `fedora` | registry.fedoraproject.org/fedora:latest | ~500MB | Bleeding edge, good for RH ecosystem |
| `debian` | debian:stable-slim | ~100MB | Rock solid, minimal base |
| `ubuntu` | ubuntu:minimal | ~100MB | Popular, good support |
| `alpine` | alpine:latest | ~50MB | Ultra-minimal, musl libc |
| `kali` | kalilinux/kali-rolling | ~1.5GB | Security testing distro |

## Modifier Flags

Flags can be combined in any order:

### `--minimal`
Strips unnecessary packages to reduce size:
- Removes documentation (`/usr/share/doc`, `/usr/share/man`)
- Keeps only `en_US.UTF-8` locale
- Keeps only `UTC` timezone
- Removes package caches
- Cleans log files
- **Result**: 20-50% smaller containers

### `--dev`
Installs development toolchain:
- Build tools (gcc, make, cmake)
- Version control (git)
- Text editor (vim)
- Utilities (curl, wget, jq, tree, htop)
- Compression tools (zip, unzip, tar)
- SSL/TLS tools (openssl)

### `--pentest`
Installs penetration testing tools:
- Network scanners (nmap, masscan)
- Wireless tools (aircrack-ng)
- Web testing (sqlmap, nikto)
- Password cracking (john, hashcat, hydra)
- Enumeration (gobuster, dirb)
- **Note**: Primarily designed for Kali/Debian/Ubuntu

### `--custom <packages>`
Install custom packages (comma-separated):
```bash
distrobox-template create arch --custom "nodejs,npm,yarn,docker"
```

## Naming Convention

Containers are auto-named: `<os>-<modifier>-<modifier>`

Examples:
- `arch-minimal-dev`
- `debian-minimal`
- `kali-pentest`
- `fedora-dev`

Override with `--name`:
```bash
distrobox-template create arch --minimal --dev --name my-container
```

## Commands

### Create Container
```bash
distrobox-template create <os> [flags]

# Examples
distrobox-template create arch
distrobox-template create arch --minimal
distrobox-template create arch --dev
distrobox-template create arch --minimal --dev
distrobox-template create kali --pentest
distrobox-template create debian --minimal --dev --custom "python3,pip"
```

### List Templates
```bash
distrobox-template list
```

### Export Container
```bash
distrobox-template export <container-name> [output-file]

# Examples
distrobox-template export arch-minimal-dev
distrobox-template export arch-minimal-dev my-backup.tar.gz
```

### Import Container
```bash
distrobox-template import <file> [name]

# Examples
distrobox-template import arch-minimal-dev.tar.gz
distrobox-template import arch-minimal-dev.tar.gz restored-container
```

### Create NixOS VM
```bash
distrobox-template create-vm nixos [flags]

# Examples
distrobox-template create-vm nixos
distrobox-template create-vm nixos --minimal
distrobox-template create-vm nixos --minimal --dev --name my-nixos
```

**Note**: NixOS VMs require:
- Nix package manager installed
- QEMU/KVM
- ~2GB disk space for initial build

## Dry-Run Mode

Preview changes without creating anything:

```bash
$ distrobox-template create arch --minimal --dev --dry-run

DRY RUN - Would create the following:

Container Name: arch-minimal-dev
Base OS: arch
Base Image: ghcr.io/archlinux/archlinux:latest

Modifiers:
  ✓ --minimal (strip docs, man pages, locales)
  ✓ --dev (install dev tools)

Estimated disk space: ~500 MB + ~200 MB
```

## Directory Structure

```
distobox-configs/
├── bin/
│   └── distrobox-template          # Main CLI script
├── lib/
│   ├── base-images.sh              # OS base definitions
│   ├── modifiers.sh                # Modifier logic
│   └── vm-nixos.sh                 # NixOS VM support
├── manifests/
│   ├── arch.ini                    # distrobox-assemble manifests
│   ├── fedora.ini
│   ├── debian.ini
│   ├── ubuntu.ini
│   ├── alpine.ini
│   └── kali.ini
├── config/
│   ├── packages/
│   │   ├── dev.list                # Dev package lists
│   │   ├── pentest.list            # Pentest package lists
│   │   └── minimal-cleanup.sh      # Minimal cleanup script
│   └── nixos/
│       └── *.nix                   # NixOS VM configurations
└── README.md
```

## Using with distrobox-assemble

Pre-made manifests are provided for declarative container management:

```bash
# Create from manifest
distrobox assemble create --file manifests/arch.ini --name arch-minimal

# Replace existing
distrobox assemble create --file manifests/arch.ini --name arch-minimal --replace
```

## Storage Options

### Keep as Live Containers
- **Pros**: Fast to clone, easy to modify, integrated with host
- **Cons**: Uses more disk over time
- **Best for**: Active development, experimentation

### Export as Images
- **Pros**: Portable, version controlled, can delete containers
- **Cons**: Slower to create, need to import to use
- **Best for**: Distribution, backup, immutable templates

```bash
# Export for backup
distrobox-template export arch-minimal-dev arch-backup.tar.gz

# Import later
distrobox-template import arch-backup.tar.gz
```

## Not Supported

| OS | Reason |
|-----|--------|
| **QubesOS** | Requires Xen hypervisor, incompatible with containers |
| **Tails** | Designed for live USB amnesic operation |
| **NixOS** | Works only as VM, not container (see `create-vm` command) |

## Troubleshooting

### Container creation fails
```bash
# Check distrobox is installed
distrobox --version

# Check podman/docker is working
podman info
# or
docker info
```

### Permission denied
```bash
# Make script executable
chmod +x ~/distrobox-configs/bin/distrobox-template

# Or use bash directly
bash ~/distrobox-configs/bin/distrobox-template create arch
```

### Package installation fails
Some packages may not be available on all distros. The script will continue with warnings.

### NixOS VM build fails
Ensure Nix is properly installed:
```bash
curl -L https://nixos.org/nix/install | sh
. ~/.nix-profile/etc/profile.d/nix.sh
```

## Requirements

- **distrobox** (on Bazzite: `ujust distrobox`)
- **podman** or **docker**
- **bash** 4.0+
- For NixOS VMs: **nix** package manager, **QEMU**

## License

MIT

## Contributing

Pull requests welcome! Especially:
- Additional OS support
- More modifier flags
- Improved cleanup scripts
- Better NixOS VM configurations
