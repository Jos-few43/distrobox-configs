#!/bin/bash
#
# vm-nixos.sh - NixOS VM creation helper
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

# Source base images
source "$SCRIPT_DIR/base-images.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() { echo -e "${RED}ERROR:${NC} $1" >&2; }
print_success() { echo -e "${GREEN}SUCCESS:${NC} $1"; }
print_warning() { echo -e "${YELLOW}WARNING:${NC} $1"; }
print_info() { echo -e "${BLUE}INFO:${NC} $1"; }

# Check if Nix is installed
check_nix() {
    if ! command -v nix &> /dev/null; then
        print_error "Nix package manager is not installed"
        print_info "Install Nix: curl -L https://nixos.org/nix/install | sh"
        return 1
    fi
    return 0
}

# Check if QEMU is available
check_qemu() {
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        print_error "QEMU is not installed"
        print_info "On Bazzite: rpm-ostree install qemu"
        return 1
    fi
    return 0
}

# Create NixOS VM
create_nixos_vm_helper() {
    local args=("$@")
    local minimal=false
    local dev=false
    local dry_run=false
    local vm_name=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --minimal)
                minimal=true
                shift
                ;;
            --dev)
                dev=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --name)
                vm_name="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Generate VM name if not provided
    if [[ -z "$vm_name" ]]; then
        vm_name="nixos"
        [[ "$minimal" == true ]] && vm_name="${vm_name}-minimal"
        [[ "$dev" == true ]] && vm_name="${vm_name}-dev"
        vm_name="${vm_name}-vm"
    fi
    
    # Dry run
    if [[ "$dry_run" == true ]]; then
        print_info "DRY RUN - Would create NixOS VM:"
        echo ""
        echo "VM Name: $vm_name"
        echo "Minimal: $minimal"
        echo "Dev Tools: $dev"
        echo ""
        echo "Requirements:"
        echo "  - Nix package manager"
        echo "  - QEMU/KVM"
        echo "  - ~2GB disk space"
        echo ""
        echo "Configuration:"
        echo "  CPU: 2 cores"
        echo "  RAM: 2GB"
        echo "  Disk: 20GB"
        return 0
    fi
    
    # Check prerequisites
    if ! check_nix; then
        return 1
    fi
    
    if ! check_qemu; then
        print_warning "QEMU not found, attempting to continue..."
    fi
    
    print_info "Creating NixOS VM: $vm_name"
    
    # Create VM directory
    local vm_dir="$HOME/.local/share/nixos-vms/$vm_name"
    mkdir -p "$vm_dir"
    
    # Generate configuration
    local config_file="$vm_dir/configuration.nix"
    generate_nixos_config "$config_file" "$minimal" "$dev"
    
    print_info "Building NixOS VM..."
    print_info "This will download NixOS and build the VM (may take 10-30 minutes)"
    
    # Build the VM
    cd "$vm_dir"
    if nix-build '<nixpkgs/nixos>' -A vm -I nixos-config="$config_file" --out-link ./result; then
        print_success "NixOS VM built successfully!"
        print_info "Start the VM with: $vm_dir/result/bin/run-$vm_name-vm"
        print_info "VM files location: $vm_dir"
        
        # Create convenience script
        cat > "$vm_dir/start-vm.sh" << EOF
#!/bin/bash
# Start NixOS VM: $vm_name
cd "$vm_dir"
exec ./result/bin/run-$vm_name-vm "\$@"
EOF
        chmod +x "$vm_dir/start-vm.sh"
        
        print_info "Or use: $vm_dir/start-vm.sh"
    else
        print_error "Failed to build NixOS VM"
        return 1
    fi
}

# Generate NixOS configuration
generate_nixos_config() {
    local output_file=$1
    local minimal=$2
    local dev=$3
    
    cat > "$output_file" << 'EOF'
{ config, pkgs, ... }:

{
  # Basic system configuration
  boot.loader.grub.device = "/dev/vda";
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Enable QEMU guest agent for better integration
  services.qemuGuest.enable = true;
  
  # Enable SSH
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  
  # Set root password (change this!)
  users.users.root.initialPassword = "nixos";
  
  # Create user account
  users.users.nixuser = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";
  };
  
  # Enable passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;
  
  # System packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    vim
    curl
    wget
    htop
    tree
EOF

    # Add dev packages if requested
    if [[ "$dev" == true ]]; then
        cat >> "$output_file" << 'EOF'
    # Development tools
    gcc
    gnumake
    cmake
    python3
    nodejs
    go
    rustup
EOF
    fi

    cat >> "$output_file" << 'EOF'
  ];
  
  # Minimal configuration
EOF

    if [[ "$minimal" == true ]]; then
        cat >> "$output_file" << 'EOF'
  # Disable unnecessary services for minimal footprint
  services.xserver.enable = false;
  documentation.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;
  programs.command-not-found.enable = false;
  
  # Minimal environment
  environment.noXlibs = true;
  boot.kernelParams = [ "quiet" ];
EOF
    else
        cat >> "$output_file" << 'EOF'
  # Enable basic X server for GUI apps (optional)
  services.xserver.enable = false;  # Set to true if you need GUI
EOF
    fi

    cat >> "$output_file" << 'EOF'
  
  # Network configuration
  networking.useDHCP = true;
  networking.hostName = "nixos-vm";
  
  # Time zone
  time.timeZone = "UTC";
  
  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Nix configuration
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # This value determines the NixOS release
  system.stateVersion = "24.11";
}
EOF
}

# Export for use in main script
export -f create_nixos_vm_helper
export -f check_nix
export -f check_qemu
