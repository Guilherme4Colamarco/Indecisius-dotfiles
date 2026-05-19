#!/usr/bin/env bash

# ============================================
# Indecisius Dotfiles Installer
# ============================================
# For CachyOS / Arch Linux with MangoWM.
# Safe by default: dry-run unless --apply is passed.
# ============================================

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY=0
WITH_AUR=0
DRY_RUN=1
ASSUME_YES=0

if [ "${EUID}" -eq 0 ]; then
    echo "Run this installer as your normal user, not with sudo/root."
    exit 1
fi

# ============================================
# Colors & Output
# ============================================
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; PURPLE=''; CYAN=''; WHITE=''; NC=''
fi

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

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

run_privileged() { run sudo "$@"; }

timestamp() { date +%Y%m%d-%H%M%S; }

usage() {
    cat <<'EOF'
Usage: ./install.sh [--apply] [--with-aur] [--yes]

Default mode is a dry-run: it prints what would change without touching files.

  --apply     actually install packages and copy configs
  --with-aur  allow AUR package installation/bootstrap
  -y, --yes   skip interactive confirmations
  -h, --help  show this help
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --apply)
                APPLY=1
                DRY_RUN=0
                ;;
            --with-aur)
                WITH_AUR=1
                ;;
            -y|--yes)
                ASSUME_YES=1
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

ask_confirmation() {
    local message="$1"
    local default="${2:-n}"

    if [ "$ASSUME_YES" -eq 1 ]; then
        print_info "$message yes (--yes)"
        return 0
    fi

    echo -e "${YELLOW}$message${NC}"
    if [ "$default" = "y" ]; then echo -n "(Y/n): "; else echo -n "(y/N): "; fi
    read -r response
    case "${response:-$default}" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

copy_path_with_backup() {
    local source_path="$1"
    local dest_parent="$2"
    local source_name
    local final_dest
    local backup_path

    source_name="$(basename "$source_path")"
    final_dest="${dest_parent%/}/${source_name}"

    if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
        print_warning "Skipping missing source: $source_path"
        return 0
    fi

    run mkdir -p "$dest_parent"

    if [ -e "$final_dest" ] || [ -L "$final_dest" ]; then
        backup_path="${final_dest}.$(timestamp).bak"
        print_info "Backing up existing $final_dest to $backup_path"
        run mv "$final_dest" "$backup_path"
    fi

    print_info "Installing $source_name to $final_dest"
    run cp -a "$source_path" "$final_dest"
    print_success "Installed $source_name"
}

copy_tree_contents_with_backup() {
    local source_dir="$1"
    local dest_dir="$2"

    if [ ! -d "$source_dir" ]; then
        print_warning "Skipping missing source directory: $source_dir"
        return 0
    fi

    run mkdir -p "$dest_dir"
    while IFS= read -r -d '' item; do
        copy_path_with_backup "$item" "$dest_dir"
    done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -print0 | sort -z)
}

# ============================================
# Detection
# ============================================
detect_system() {
    print_header "🔍 Detecting System"
    CACHYOS=false

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
            cachyos)
                CACHYOS=true
                print_success "CachyOS detected — MangoWM native support"
                ;;
            arch|manjaro|endeavouros)
                print_warning "Arch-based distro detected, but not CachyOS"
                print_info "mangowm may not be available in standard repos."
                print_info "You may need CachyOS repos, AUR, or a manual MangoWM build."
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
    if [ "$WITH_AUR" -ne 1 ]; then
        print_warning "AUR bootstrap disabled. Re-run with --with-aur to enable it."
        return 1
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        print_info "Would install git/base-devel and bootstrap yay in a temporary directory."
        return 1
    fi

    run_privileged pacman -S --needed --noconfirm git base-devel

    local tmpdir
    tmpdir="$(mktemp -d -t indecisius-aur.XXXXXX)"
    trap 'rm -rf "$tmpdir"' RETURN

    if git clone https://aur.archlinux.org/yay.git "$tmpdir/yay" 2>/dev/null; then
        (cd "$tmpdir/yay" && makepkg -si --noconfirm)
        print_success "yay installed"
        return 0
    fi

    if git clone https://aur.archlinux.org/paru.git "$tmpdir/paru" 2>/dev/null; then
        (cd "$tmpdir/paru" && makepkg -si --noconfirm)
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
        print_success "Package step complete: ${to_install[*]}"
    fi
}

install_aur_packages() {
    local packages=("$@")
    local to_install=()
    local aur_helper=""

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

    if command_exists yay; then aur_helper="yay"
    elif command_exists paru; then aur_helper="paru"
    fi

    if [ -z "$aur_helper" ]; then
        print_error "No AUR helper available. Skipping: ${to_install[*]}"
        return 1
    fi

    print_info "Installing ${#to_install[@]} AUR packages via $aur_helper..."
    run "$aur_helper" -S --needed --noconfirm "${to_install[@]}"
    print_success "AUR package step complete: ${to_install[*]}"
}

# ============================================
# Main Logic
# ============================================
main() {
    parse_args "$@"

    print_header "🥭 Indecisius Dotfiles Installer"
    echo -e "${CYAN}MangoWM-focused rice for CachyOS.${NC}\n"
    if [ "$DRY_RUN" -eq 1 ]; then
        print_warning "Dry-run mode: no packages/files will be changed. Use --apply to install."
    fi

    detect_system

    if ! ask_confirmation "Continue with installation?"; then
        echo -e "${YELLOW}Cancelled.${NC}"
        exit 0
    fi

    print_section "System Update"
    print_info "Skipping full system upgrade. Run 'sudo pacman -Syu' yourself when desired."

    print_section "Installing Core Packages"
    CORE_PKGS=(
        mangowm wlr-randr
        waybar wofi cava mako matugen jq
        kitty fish starship zoxide
        cliphist wl-clipboard
        grim slurp swappy
        brightnessctl
        gnome-keyring polkit polkit-gnome
        xdg-desktop-portal xdg-desktop-portal-wlr xdg-user-dirs
        dbus
        ttf-jetbrains-mono-nerd ttf-font-awesome
    )
    install_packages "${CORE_PKGS[@]}"

    print_section "Installing Optional AUR Packages"
    AUR_PKGS=()
    if ! package_installed waypaper; then AUR_PKGS+=(waypaper); fi
    if ! package_installed wlogout; then AUR_PKGS+=(wlogout); fi
    if ! command_exists awww && ! package_installed awww; then AUR_PKGS+=(awww); fi

    if [ ${#AUR_PKGS[@]} -gt 0 ]; then
        if [ "$WITH_AUR" -ne 1 ]; then
            print_warning "AUR packages needed but disabled: ${AUR_PKGS[*]}"
            print_info "Re-run with --with-aur if you want the installer to manage AUR packages."
        else
            setup_aur || print_warning "AUR helper unavailable — skipping AUR packages"
            if command_exists yay || command_exists paru; then
                install_aur_packages "${AUR_PKGS[@]}"
            fi
        fi
    else
        print_success "No optional AUR packages needed"
    fi

    print_section "Installing Configuration Files"
    copy_tree_contents_with_backup "${REPO_ROOT}/.config" "${HOME}/.config"
    copy_tree_contents_with_backup "${REPO_ROOT}/.icons" "${HOME}/.icons"
    copy_tree_contents_with_backup "${REPO_ROOT}/.local/share/applications" "${HOME}/.local/share/applications"

    print_section "Post-Installation"
    print_info "Setting up user directories..."
    if command_exists xdg-user-dirs-update; then
        run xdg-user-dirs-update 2>/dev/null || true
    else
        print_warning "xdg-user-dirs-update not found; skipping user directory setup"
    fi

    local fish_path
    fish_path="$(command -v fish || true)"
    if [ -n "$fish_path" ] && [ "${SHELL:-}" != "$fish_path" ]; then
        if ask_confirmation "Set fish as your default shell?" "n"; then
            run chsh -s "$fish_path"
            print_success "Fish set as default shell (applies on next login)"
        fi
    fi

    print_header "🎉 Installation Complete!"
    echo -e "${GREEN}Indecisius MangoWM dotfiles install finished.${NC}"
    echo -e "${WHITE}What was set up:${NC}"
    echo -e "  ${CHECKMARK} MangoWM + Waybar + Wofi + Mako"
    echo -e "  ${CHECKMARK} Kitty terminal + Fish shell"
    echo -e "  ${CHECKMARK} Clipboard, screenshots, wallpaper, and power menu tooling"
    echo -e "  ${CHECKMARK} Existing config paths backed up with timestamped .bak suffixes"
    echo -e "${WHITE}Next steps:${NC}"
    echo -e "  ${ARROW} Log out and select 'Mango' in your display manager"
    echo -e "  ${ARROW} Or run: mango --config ~/.config/mango/config.conf"
    echo -e "  ${ARROW} Enjoy your rice! 🍚"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
