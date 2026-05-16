#!/bin/bash

# ============================================
# Mango WM Dotfiles Installer
# ============================================
# For CachyOS / Arch Linux with Mango (Hyprland wrapper)
# Barebones minimal install — no DE, just Mango + ecosystem
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
package_installed() { pacman -Qi "$1" &>/dev/null; }
run_privileged() { if [ "$EUID" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

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
detect_system() {
    print_header "🔍 Detecting System"
    CACHYOS=false

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            "cachyos")
                CACHYOS=true
                print_success "CachyOS detected — Mango WM native support"
                ;;
            "arch"|"manjaro"|"endeavouros")
                print_warning "Arch-based detected, but not CachyOS"
                print_info "mangowm may not be available in standard repos."
                print_info "You may need to build it manually or use hyprland."
                ;;
            *)
                print_error "This installer is designed for CachyOS / Arch Linux."
                print_error "Distro '$ID' is not supported."
                exit 1
                ;;
        esac
    else
        print_error "Cannot detect distro"
        exit 1
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
    run_privileged pacman -S --needed --noconfirm git base-devel

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

    print_error "Failed to install AUR helper."
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
        run_privileged pacman -S --needed --noconfirm "${to_install[@]}"
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
        print_error "No AUR helper available. Skipping: ${to_install[*]}"
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
    print_header "🥭 Mango WM Dotfiles Installer"
    echo -e "${CYAN}Minimal rice for CachyOS.${NC}\n"

    detect_system

    if ! ask_confirmation "Continue with installation?"; then
        echo -e "${YELLOW}Cancelled.${NC}"
        exit 0
    fi

    # Update system
    print_section "Updating System"
    run_privileged pacman -Syu --noconfirm
    print_success "System updated"

    # Core packages
    print_section "Installing Core Packages"
    CORE_PKGS=(
        mangowm wlr-randr
        waybar rofi mako
        kitty fish
        cliphist wl-clipboard
        grim slurp swappy
        brightnessctl
        gnome-keyring polkit polkit-gnome
        xdg-desktop-portal xdg-desktop-portal-wlr
        dbus
        ttf-jetbrains-mono-nerd ttf-font-awesome
    )
    install_packages "${CORE_PKGS[@]}"

    # AUR packages
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
        setup_aur || print_warning "AUR helper unavailable — skipping AUR packages"
        if command_exists yay || command_exists paru; then
            install_aur_packages "${AUR_PKGS[@]}"
        fi
    fi

    # Copy configs
    print_section "Installing Configuration Files"
    mkdir -p ~/.config

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

    # Post-install
    print_section "Post-Installation"
    print_info "Setting up user directories..."
    xdg-user-dirs-update 2>/dev/null || true

    if command_exists fish; then
        if [ "$SHELL" != "$(which fish)" ]; then
            if ask_confirmation "Set fish as your default shell?" "n"; then
                chsh -s "$(which fish)"
                print_success "Fish set as default shell (applies on next login)"
            fi
        fi
    fi

    print_header "🎉 Installation Complete!"
    echo -e "${GREEN}Mango WM dotfiles installed successfully!${NC}"
    echo -e "${WHITE}What's been set up:${NC}"
    echo -e "  ${CHECKMARK} Mango WM + Waybar + Rofi + Mako"
    echo -e "  ${CHECKMARK} Kitty terminal + Fish shell"
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
