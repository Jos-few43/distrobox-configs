#!/bin/bash
#
# minimal-cleanup.sh - Strip unnecessary packages for ultra-minimal containers
# This script runs inside the container
#

echo "Starting minimal cleanup..."

# Detect package manager
if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu/Kali
    
    # Remove documentation
    echo "Removing documentation..."
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*
    
    # Remove locales except en_US.UTF-8
    echo "Removing extra locales..."
    find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en_US' -exec rm -rf {} + 2>/dev/null || true
    
    # Remove timezone data except UTC
    echo "Removing extra timezone data..."
    find /usr/share/zoneinfo -mindepth 1 -maxdepth 1 ! -name 'UTC' -exec rm -rf {} + 2>/dev/null || true
    
    # Remove unnecessary services
    echo "Removing unnecessary services..."
    apt-get purge -y --auto-remove \
        e2fsprogs \
        libx11-data \
        xauth \
        2>/dev/null || true
    
    # Clean package caches
    echo "Cleaning package caches..."
    apt-get clean
    apt-get autoremove -y
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
    
    # Remove log files
    echo "Cleaning log files..."
    find /var/log -type f -delete 2>/dev/null || true
    
    # Remove temporary files
    rm -rf /tmp/* /var/tmp/*
    
    # Remove kernel modules (not needed in container)
    rm -rf /lib/modules/*/kernel/drivers 2>/dev/null || true
    
    # Create locale.gen with only en_US.UTF-8
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    
elif command -v pacman &> /dev/null; then
    # Arch Linux
    
    # Remove documentation
    echo "Removing documentation..."
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*
    
    # Remove locales except en_US
    echo "Removing extra locales..."
    find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en_US' -exec rm -rf {} + 2>/dev/null || true
    
    # Remove timezone data except UTC
    echo "Removing extra timezone data..."
    find /usr/share/zoneinfo -mindepth 1 -maxdepth 1 ! -name 'UTC' -exec rm -rf {} + 2>/dev/null || true
    
    # Clean package cache
    echo "Cleaning package caches..."
    pacman -Scc --noconfirm
    
    # Remove log files
    echo "Cleaning log files..."
    find /var/log -type f -delete 2>/dev/null || true
    
    # Remove temporary files
    rm -rf /tmp/* /var/tmp/*
    
    # Remove kernel modules
    rm -rf /lib/modules/*/kernel/drivers 2>/dev/null || true
    
elif command -v dnf &> /dev/null; then
    # Fedora
    
    # Remove documentation
    echo "Removing documentation..."
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*
    
    # Remove locales except en_US
    echo "Removing extra locales..."
    find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en_US' -exec rm -rf {} + 2>/dev/null || true
    
    # Remove timezone data except UTC
    echo "Removing extra timezone data..."
    find /usr/share/zoneinfo -mindepth 1 -maxdepth 1 ! -name 'UTC' -exec rm -rf {} + 2>/dev/null || true
    
    # Clean package cache
    echo "Cleaning package caches..."
    dnf clean all
    
    # Remove log files
    echo "Cleaning log files..."
    find /var/log -type f -delete 2>/dev/null || true
    
    # Remove temporary files
    rm -rf /tmp/* /var/tmp/*
    
    # Remove kernel modules
    rm -rf /lib/modules/*/kernel/drivers 2>/dev/null || true
    
elif command -v apk &> /dev/null; then
    # Alpine Linux
    
    # Remove documentation (Alpine is already minimal)
    echo "Removing documentation..."
    rm -rf /usr/share/doc/* /usr/share/man/*
    
    # Remove locales (Alpine doesn't ship many by default)
    echo "Removing extra locales..."
    find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en_US' -exec rm -rf {} + 2>/dev/null || true
    
    # Clean package cache
    echo "Cleaning package caches..."
    rm -rf /var/cache/apk/*
    
    # Remove log files
    echo "Cleaning log files..."
    find /var/log -type f -delete 2>/dev/null || true
    
    # Remove temporary files
    rm -rf /tmp/* /var/tmp/*
    
fi

# Common cleanup across all distros

# Remove history files
rm -f /root/.bash_history /root/.zsh_history /home/*/.bash_history /home/*/.zsh_history 2>/dev/null || true

# Remove SSH host keys (containers shouldn't share these)
rm -f /etc/ssh/ssh_host_* 2>/dev/null || true

# Clear shell history in memory
history -c 2>/dev/null || true

echo "Minimal cleanup complete!"
echo "Container size reduction: 20-50%"
