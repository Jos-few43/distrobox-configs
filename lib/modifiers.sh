#!/bin/bash
#
# modifiers.sh - Apply modifications to template containers
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

# Source base images
source "$SCRIPT_DIR/base-images.sh"

# Apply minimal cleanup
apply_minimal() {
    local container=$1
    local os=$2
    
    local cleanup_script="$CONFIG_DIR/packages/minimal-cleanup.sh"
    
    if [[ ! -f "$cleanup_script" ]]; then
        echo "Warning: Cleanup script not found at $cleanup_script" >&2
        return 1
    fi
    
    # Copy script to container and execute
    distrobox enter "$container" -- bash -c "
        $(cat "$cleanup_script")
    " 2>&1 || return 1
    
    return 0
}

# Apply dev tools
apply_dev() {
    local container=$1
    local os=$2
    
    local dev_packages="$CONFIG_DIR/packages/dev.list"
    local install_cmd=$(get_install_prefix "$os")
    local update_cmd=$(get_update_cmd "$os")
    local cleanup_cmd=$(get_cleanup_cmd "$os")
    
    # Get packages for this OS
    local packages=""
    if [[ -f "$dev_packages" ]]; then
        packages=$(grep -E "^$os:" "$dev_packages" | cut -d: -f2- | tr ',' ' ')
    fi
    
    # Fallback to common dev tools if no specific list
    if [[ -z "$packages" ]]; then
        case $os in
            arch)
                packages="base-devel git vim curl wget"
                ;;
            fedora)
                packages="@development-tools git vim curl wget"
                ;;
            debian|ubuntu|kali)
                packages="build-essential git vim curl wget"
                ;;
            alpine)
                packages="build-base git vim curl wget"
                ;;
        esac
    fi
    
    # Install packages
    distrobox enter "$container" -- bash -c "
        set -e
        echo 'Updating package database...'
        $update_cmd
        echo 'Installing development tools...'
        $install_cmd $packages
        echo 'Cleaning up...'
        $cleanup_cmd
    " 2>&1 || return 1
    
    return 0
}

# Apply pentest tools
apply_pentest() {
    local container=$1
    local os=$2
    
    # Pentest tools primarily for Kali, but can work on Debian/Ubuntu
    local pentest_packages="$CONFIG_DIR/packages/pentest.list"
    local install_cmd=$(get_install_prefix "$os")
    local update_cmd=$(get_update_cmd "$os")
    local cleanup_cmd=$(get_cleanup_cmd "$os")
    
    if [[ "$os" != "kali" && "$os" != "debian" && "$os" != "ubuntu" ]]; then
        echo "Warning: Pentest tools are primarily designed for Debian-based systems" >&2
        echo "Attempting installation anyway..." >&2
    fi
    
    local packages=""
    if [[ -f "$pentest_packages" ]]; then
        packages=$(grep -E "^$os:" "$pentest_packages" | cut -d: -f2- | tr ',' ' ')
    fi
    
    # Default packages if none specified
    if [[ -z "$packages" ]]; then
        case $os in
            kali)
                packages="kali-linux-headless"
                ;;
            debian|ubuntu)
                packages="nmap ncat masscan wireshark metasploit-framework"
                ;;
            *)
                packages="nmap"
                ;;
        esac
    fi
    
    # Install packages
    distrobox enter "$container" -- bash -c "
        set -e
        echo 'Updating package database...'
        $update_cmd
        echo 'Installing penetration testing tools...'
        $install_cmd $packages || echo 'Some packages failed to install, continuing...'
        echo 'Cleaning up...'
        $cleanup_cmd
    " 2>&1 || return 1
    
    return 0
}

# Apply custom packages
apply_custom_packages() {
    local container=$1
    local os=$2
    local packages="$3"
    
    local install_cmd=$(get_install_prefix "$os")
    local update_cmd=$(get_update_cmd "$os")
    local cleanup_cmd=$(get_cleanup_cmd "$os")
    
    # Convert comma-separated to space-separated
    packages=$(echo "$packages" | tr ',' ' ')
    
    distrobox enter "$container" -- bash -c "
        set -e
        echo 'Updating package database...'
        $update_cmd
        echo 'Installing custom packages: $packages'
        $install_cmd $packages || echo 'Some packages failed to install, continuing...'
        echo 'Cleaning up...'
        $cleanup_cmd
    " 2>&1 || return 1
    
    return 0
}
