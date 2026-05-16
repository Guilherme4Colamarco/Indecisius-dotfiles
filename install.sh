#!/bin/bash

# ============================================
# Indecisius Dotfiles - Universal Installer
# ============================================
# Auto-detects distro and desktop environment.
# Works on: Arch Linux barebones OR distros with pre-configured DE.
# Supports: Arch Linux, CachyOS, Manjaro, EndeavourOS
# ============================================

if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================
# Colors & Output
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

CHECKMARK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
ARROW="${BLUE}→${NC}"
WARNING="${YELLOW}⚠${NC}"
INFO="${CYAN}ℹ${NC}"

print_header() {
    echo -e "\n${PURPLE}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════════════════${NC}"
}

print_section() {
    echo -e "\n${BLUE}┌─────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${WHITE}$1${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────────────────┘${NC}"
}

print_success() { echo -e "${CHECKMARK} $1"; }
print_error()   { echo -e "${CROSS} $1"; }
print_warning() { echo -e "${WARNING} $1"; }
print_info()    { echo -e "${INFO} $1"; }

# ============================================
# Utility Functions
# ============================================
command_exists() { command -v "$1" &>/dev/null; }

package_installed() {
    case "$DISTRO" in
        "arch") pacman -Qi "$1" &>/dev/null ;;
        "fedora") rpm -q "$1" &>/dev/null ;;
        "debian") dpkg -l "$1" 2>/dev/null | grep -q "^ii" ;;
        *) return 1 ;;
    esac
}

run_privileged() {
    if [ "$EUID" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

ask_confirmation() {
    local message="$1"
    local default="${2:-n}"
    echo -e "${YELLOW}$message${NC}"
    if [ "$default" = "y" ]; then echo -n "(Y/n): "; else echo -n "(y/N): "; fi
    read -r response
    case "${response:-$default}" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

copy_config_with_backup() {
    local source_dir="$1"
    local dest_dir="$2"
    local backup_suffix="${3:-.bak}"
    local source_name=$(basename "$source_dir")
    local final_dest="${dest_dir}/${source_name}"

    if [ -d "$final_dest" ]; then
        local backup_dir="${final_dest}${backup_suffix}"
        if [ -d "$backup_dir" ]; then
            mv "$backup_dir" "${backup_dir}.old" 2>/dev/null || true
        fi
        print_info "Backing up existing $final_dest to $backup_dir"
        mv "$final_dest" "$backup_dir"
    fi

    print_info "Copying $source_name to $final_dest"
    cp -r "$source_dir" "$final_dest"
    print_success "Installed $source_name"
}

# ============================================
# Detection
# ============================================
detect_distro() {
    print_header "🔍 Detecting Linux Distribution"
    CACHYOS=false

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            "cachyos")
                DISTRO="arch"; DISTRO_NAME="CachyOS"; CACHYOS=true ;;
            "arch"|"manjaro"|"endeavouros"|"xerolinux")
                DISTRO="arch"; DISTRO_NAME="Arch Linux" ;;
            "fedora"|"nobara")
                DISTRO="fedora"; DISTRO_NAME="Fedora" ;;
            "debian"|"pika")
                DISTRO="debian"; DISTRO_NAME="Debian/PikaOS" ;;
            *)
                print_warning "Distro '$ID' not explicitly supported. Trying Arch paths..."
                DISTRO="arch"; DISTRO_NAME="$ID (Arch fallback)" ;;
        esac
    else
        print_error "Cannot detect distro"
        exit 1
    fi

    print_success "Detected: $DISTRO_NAME"
}

detect_de() {
    print_header "🖥️  Detecting Desktop Environment"
    HAS_DE=false
    DE_NAME="none"

    # Trust environment variables ONLY if the corresponding DE packages are actually installed
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        DE_NAME="$XDG_CURRENT_DESKTOP"
        HAS_DE=true
    elif [ -n "$DESKTOP_SESSION" ]; then
        DE_NAME="$DESKTOP_SESSION"
        HAS_DE=true
    fi

    # Verify DE is actually installed (Arch)
    if [ "$DISTRO" = "arch" ]; then
        local de_verified=false
        if pacman -Qi gnome-session &>/dev/null; then DE_NAME="GNOME"; de_verified=true; fi
        if pacman -Qi plasma-workspace &>/dev/null; then DE_NAME="KDE Plasma"; de_verified=true; fi
        if pacman -Qi xfce4-session &>/dev/null; then DE_NAME="XFCE"; de_verified=true; fi
        if pacman -Qi cinnamon-session &>/dev/null; then DE_NAME="Cinnamon"; de_verified=true; fi
        if [ "$CACHYOS" = true ] && pacman -Qi mangowm &>/dev/null; then DE_NAME="Mango"; de_verified=true; fi
        if [ "$de_verified" = false ]; then
            HAS_DE=false
            DE_NAME="none"
        else
            HAS_DE=true
        fi
    fi

    # Check display manager
    if systemctl is-active display-manager &>/dev/null; then
        HAS_DE=true
    fi

    if [ "$HAS_DE" = true ]; then
        print_info "Desktop Environment detected: $DE_NAME"
        print_info "Some base packages (polkit, portals, keyring) may already be installed."
    else
        print_info "No Desktop Environment detected — assuming minimal install"
    fi
}

# ============================================
# AUR Setup
# ============================================
setup_aur() {
    if command_exists yay; then
        print_success "yay already installed"
        return 0
    fi
    if command_exists paru; then
        print_success "paru already installed"
        return 0
    fi

    print_section "Setting up AUR helper"
    run_privileged pacman -S --needed --noconfirm git base-devel ca-certificates-utils
    # Update CA certs to prevent TLS errors in containers
    run_privileged update-ca-trust 2>/dev/null || true

    cd /tmp
    rm -rf yay
    if git clone https://aur.archlinux.org/yay.git 2>/dev/null; then
        cd yay
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/yay
        print_success "yay installed"
        return 0
    fi

    # Fallback: try paru
    cd /tmp
    rm -rf paru
    if git clone https://aur.archlinux.org/paru.git 2>/dev/null; then
        cd paru
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/paru
        print_success "paru installed"
        return 0
    fi

    print_error "Failed to install AUR helper (yay/paru). Network or TLS issue?"
    print_warning "You will need to manually install AUR packages: ${AUR_PKGS[*]}"
    return 1
}

# ============================================
# Package Installation
# ============================================
install_packages() {
    local packages=("$@")
    local to_install=()

    for pkg in "${packages[@]}"; do
        if package_installed "$pkg"; then
            print_success "Already installed: $pkg"
        else
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        print_info "Installing ${#to_install[@]} packages..."
        case "$DISTRO" in
            "arch") run_privileged pacman -S --needed --noconfirm "${to_install[@]}" ;;
            "fedora") run_privileged dnf install -y "${to_install[@]}" ;;
            "debian") run_privileged apt install -y "${to_install[@]}" ;;
        esac
        print_success "Installed ${#to_install[@]} packages"
    fi
}

install_aur_packages() {
    local packages=("$@")
    local to_install=()

    for pkg in "${packages[@]}"; do
        if package_installed "$pkg"; then
            print_success "Already installed: $pkg"
        else
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        return 0
    fi

    local aur_helper=""
    if command_exists yay; then aur_helper="yay"
    elif command_exists paru; then aur_helper="paru"
    fi

    if [ -z "$aur_helper" ]; then
        print_error "No AUR helper available. Skipping AUR packages: ${to_install[*]}"
        print_info "Install yay or paru manually, then re-run this script."
        return 1
    fi

    print_info "Installing ${#to_install[@]} AUR packages via $aur_helper..."
    $aur_helper -S --needed --noconfirm "${to_install[@]}"
    print_success "Installed AUR packages"
}

# ============================================
# Main Logic
# ============================================
main() {
    print_header "🚀 Indecisius Dotfiles Installer"
    echo -e "${CYAN}Dotfiles indecisos — porque decidir é difícil.${NC}\n"

    detect_distro
    detect_de

    # Determine mode
    if [ "$HAS_DE" = true ]; then
        print_section "Mode Selection"
        echo -e "${WHITE}A Desktop Environment ($DE_NAME) was detected.${NC}"
        echo -e "${WHITE}Choose installation mode:${NC}"
        echo -e "  ${ARROW} 1) Coexist — install only missing tools, keep your DE"
        echo -e "  ${ARROW} 2) Replace — full minimal install (may conflict with DE)"
        echo
        echo -n "Enter choice (1-2) [1]: "
        read -r mode_choice
        mode_choice="${mode_choice:-1}"

        if [ "$mode_choice" = "2" ]; then
            MODE="minimal"
            print_info "Minimal mode selected — installing everything"
        else
            MODE="coexist"
            print_info "Coexist mode selected — installing only missing packages"
        fi
    else
        MODE="minimal"
        print_info "Minimal installation mode (no DE detected)"
    fi

    if ! ask_confirmation "Continue with installation?"; then
        echo -e "${YELLOW}Cancelled.${NC}"
        exit 0
    fi

    # Update system
    print_section "Updating System"
    case "$DISTRO" in
        "arch") run_privileged pacman -Syu --noconfirm ;;
        "fedora") run_privileged dnf update -y ;;
        "debian") run_privileged apt update && run_privileged apt upgrade -y ;;
    esac
    print_success "System updated"

    # Core packages (always)
    print_section "Installing Core Packages"
    if [ "$CACHYOS" = true ]; then
        WM_PKG="mangowm"
    else
        WM_PKG="hyprland"
    fi

    CORE_PKGS=(
        "$WM_PKG" wlr-randr
        waybar rofi mako
        kitty fish
        cliphist wl-clipboard
        grim slurp swappy
        brightnessctl
        ttf-jetbrains-mono-nerd ttf-font-awesome
    )

    if [ "$MODE" = "minimal" ]; then
        CORE_PKGS+=(
            gnome-keyring polkit polkit-gnome
            xdg-desktop-portal xdg-desktop-portal-wlr
            dbus
        )
    fi

    # Install based on distro
    if [ "$DISTRO" = "arch" ]; then
        install_packages "${CORE_PKGS[@]}"

        AUR_PKGS=()
        if ! command_exists rofi && ! package_installed rofi; then
            AUR_PKGS+=("rofi-wayland")
        fi
        if ! package_installed waypaper; then
            AUR_PKGS+=("waypaper")
        fi
        if ! package_installed wlogout; then
            AUR_PKGS+=("wlogout")
        fi
        if ! command_exists awww && ! package_installed awww; then
            AUR_PKGS+=("awww")
        fi

        if [ ${#AUR_PKGS[@]} -gt 0 ]; then
            # Try AUR setup, but don't abort if it fails (network/TLS issues in containers, etc.)
            setup_aur || print_warning "AUR helper unavailable — skipping AUR packages"
            if command_exists yay || command_exists paru; then
                install_aur_packages "${AUR_PKGS[@]}"
            fi
        fi
    else
        print_warning "Non-Arch distro detected. Please install equivalent packages manually."
        print_info "Required: mangowm, waybar, rofi, mako, kitty, fish, awww, waypaper, cliphist, grim, slurp, swappy, wlogout"
    fi

    # Copy configs
    print_section "Installing Configuration Files"

    mkdir -p ~/.config

    # Backup existing fish prompt if it's a symlink
    if [ -L ~/.config/fish/functions/fish_prompt.fish ]; then
        rm ~/.config/fish/functions/fish_prompt.fish
    fi

    copy_config_with_backup "${REPO_ROOT}/.config/mango" ~/.config
    copy_config_with_backup "${REPO_ROOT}/.config/waybar" ~/.config
    copy_config_with_backup "${REPO_ROOT}/.config/rofi" ~/.config
    copy_config_with_backup "${REPO_ROOT}/.config/kitty" ~/.config
    copy_config_with_backup "${REPO_ROOT}/.config/mako" ~/.config
    copy_config_with_backup "${REPO_ROOT}/.config/wlogout" ~/.config
    copy_config_with_backup "${REPO_ROOT}/.config/fastfetch" ~/.config
    copy_config_with_backup "${REPO_ROOT}/.config/fish" ~/.config
    copy_config_with_backup "${REPO_ROOT}/.config/waypaper" ~/.config

    if [ "$MODE" = "minimal" ]; then
        copy_config_with_backup "${REPO_ROOT}/.config/EventHorizon" ~/.config
    fi

    # Post-install
    print_section "Post-Installation"

    if [ "$MODE" = "minimal" ]; then
        print_info "Setting up user directories..."
        xdg-user-dirs-update 2>/dev/null || true
    fi

    # Fish as default shell?
    if command_exists fish; then
        if [ "$SHELL" != "$(which fish)" ]; then
            if ask_confirmation "Set fish as your default shell?" "n"; then
                chsh -s "$(which fish)"
                print_success "Fish set as default shell (applies on next login)"
            fi
        fi
    fi

    print_header "🎉 Installation Complete!"
    echo -e "${GREEN}Indecisius dotfiles installed successfully!${NC}"
    echo -e "${WHITE}What's been set up:${NC}"
    echo -e "  ${CHECKMARK} Mango WM + Waybar + Rofi + Mako"
    echo -e "  ${CHECKMARK} Kitty terminal + Fish shell"
    echo -e "  ${CHECKMARK} awww wallpaper daemon + waypaper"
    echo -e "  ${CHECKMARK} Clipboard, screenshots, power menu"
    echo -e "  ${CHECKMARK} Configs backed up with .bak extension"
    echo -e "${WHITE}Next steps:${NC}"
    echo -e "  ${ARROW} Log out and select 'Mango' in your display manager"
    echo -e "  ${ARROW} Or run: mango --config ~/.config/mango/config.conf"
    echo -e "  ${ARROW} Enjoy your rice! 🍚"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
