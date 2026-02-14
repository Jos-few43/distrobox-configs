#!/bin/bash
#
# base-images.sh - Base OS image definitions for distrobox-template
#

# Get base image URL for OS
get_base_image() {
    local os=$1
    
    case $os in
        arch)
            echo "ghcr.io/archlinux/archlinux:latest"
            ;;
        fedora)
            echo "registry.fedoraproject.org/fedora:latest"
            ;;
        debian)
            echo "debian:stable-slim"
            ;;
        ubuntu)
            echo "ubuntu:minimal"
            ;;
        alpine)
            echo "alpine:latest"
            ;;
        kali)
            echo "kalilinux/kali-rolling"
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
}

# Check if OS is valid
is_valid_os() {
    local os=$1
    case $os in
        arch|fedora|debian|ubuntu|alpine|kali)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get package manager for OS
get_package_manager() {
    local os=$1
    
    case $os in
        arch)
            echo "pacman"
            ;;
        fedora)
            echo "dnf"
            ;;
        debian|ubuntu|kali)
            echo "apt"
            ;;
        alpine)
            echo "apk"
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
}

# Get update command for OS
get_update_cmd() {
    local os=$1
    
    case $os in
        arch)
            echo "pacman -Syu --noconfirm"
            ;;
        fedora)
            echo "dnf update -y"
            ;;
        debian|ubuntu|kali)
            echo "apt-get update && apt-get upgrade -y"
            ;;
        alpine)
            echo "apk update && apk upgrade"
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
}

# Get install command prefix for OS
get_install_prefix() {
    local os=$1
    
    case $os in
        arch)
            echo "pacman -S --noconfirm"
            ;;
        fedora)
            echo "dnf install -y"
            ;;
        debian|ubuntu|kali)
            echo "apt-get install -y"
            ;;
        alpine)
            echo "apk add"
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
}

# Get cleanup command for OS
get_cleanup_cmd() {
    local os=$1
    
    case $os in
        arch)
            echo "pacman -Scc --noconfirm"
            ;;
        fedora)
            echo "dnf clean all"
            ;;
        debian|ubuntu|kali)
            echo "apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*"
            ;;
        alpine)
            echo "rm -rf /var/cache/apk/*"
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
}
