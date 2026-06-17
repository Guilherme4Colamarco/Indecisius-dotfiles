#!/usr/bin/env bash

# ============================================
# Indecisius Dotfiles Uninstaller
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
RESTORE_SNAPSHOT=0
REMOVE_PACKAGES=1
RESTORE_CONFIGS=1
REMOVE_SESSION=1

if [ "${EUID}" -eq 0 ]; then
    echo "Run this uninstaller as your normal user, not with sudo/root."
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
Usage: ./uninstall.sh [options]

Default mode is a dry-run: it prints what would change without touching files.

  --apply            actually remove packages and restore configs
  --with-aur         also remove AUR packages (waypaper, wlogout, awww, swaync)
  --no-package-remove  skip package removal, only restore configs
  --no-config-restore  skip config restoration, only remove packages
  --no-session-remove  keep the wayland-sessions entry
  --restore-snapshot   offer to restore snapper/timeshift snapshot from before install
  -y, --yes          skip interactive confirmations
  -h, --help         show this help
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
            --no-package-remove)
                REMOVE_PACKAGES=0
                ;;
            --no-config-restore)
                RESTORE_CONFIGS=0
                ;;
            --no-session-remove)
                REMOVE_SESSION=0
                ;;
            --restore-snapshot)
                RESTORE_SNAPSHOT=1
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
                usage >&2
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

# ============================================
# Config Restoration
# ============================================
restore_configs() {
    print_section "Restoring Configuration Files"

    local target="$HOME/.config"
    local backup_root="$HOME/.config-stow-backup-*"
    local dotfiles_backup="$HOME/.dotfiles-backup-*"

    # Find most recent stow backup
    local latest_stow_backup=""
    for dir in $backup_root; do
        [ -d "$dir" ] && latest_stow_backup="$dir"
    done

    # Find most recent dotfiles backup
    local latest_dotfiles_backup=""
    for dir in $dotfiles_backup; do
        [ -d "$dir" ] && latest_dotfiles_backup="$dir"
    done

    if [ -z "$latest_stow_backup" ] && [ -z "$latest_dotfiles_backup" ]; then
        print_warning "No backup directories found. Nothing to restore."
        return 0
    fi

    local restored_any=0

    # Restore from stow backup
    if [ -n "$latest_stow_backup" ]; then
        print_info "Found stow backup: $latest_stow_backup"
        if ask_confirmation "Restore configs from stow backup?" "y"; then
            # Use stow to unlink first, then copy back
            if command_exists stow; then
                print_info "Unlinking stow packages..."
                run stow -v -d "$REPO_ROOT" -t "$target" -D Configs 2>/dev/null || true
            fi
            # Copy back backed up files
            if [ -d "$latest_stow_backup" ]; then
                run cp -a "$latest_stow_backup"/* "$target/" 2>/dev/null || true
                print_success "Restored from stow backup"
                restored_any=1
            fi
        fi
    fi

    # Restore from dotfiles backup
    if [ -n "$latest_dotfiles_backup" ]; then
        print_info "Found dotfiles backup: $latest_dotfiles_backup"
        if ask_confirmation "Restore configs from dotfiles backup?" "y"; then
            # Copy back backed up files
            run cp -a "$latest_dotfiles_backup"/* "$HOME/" 2>/dev/null || true
            print_success "Restored from dotfiles backup"
            restored_any=1
        fi
    fi

    if [ "$restored_any" -eq 0 ]; then
        print_warning "No configs restored"
    fi
}

# ============================================
# Session Entry Removal
# ============================================
remove_session_entry() {
    print_section "Removing Mango Session Entry"

    local session_file="$HOME/.local/share/wayland-sessions/mango.desktop"

    if [ -f "$session_file" ]; then
        print_info "Found session file: $session_file"
        if ask_confirmation "Remove Mango session entry?" "y"; then
            run rm -f "$session_file"
            print_success "Session entry removed"
        fi
    else
        print_info "No session entry found at $session_file"
    fi
}

# ============================================
# Package Removal
# ============================================
remove_packages() {
    local packages=("$@")
    local to_remove=()

    for pkg in "${packages[@]}"; do
        if package_installed "$pkg"; then
            print_info "Will remove: $pkg"
            to_remove+=("$pkg")
        else
            print_success "Not installed: $pkg"
        fi
    done

    if [ ${#to_remove[@]} -gt 0 ]; then
        print_info "Removing ${#to_remove[@]} packages..."
        run_privileged pacman -Rns --noconfirm "${to_remove[@]}"
        print_success "Package removal complete: ${to_remove[*]}"
    else
        print_success "No packages to remove"
    fi
}

remove_aur_packages() {
    local packages=("$@")
    local to_remove=()
    local aur_helper=""

    for pkg in "${packages[@]}"; do
        if package_installed "$pkg"; then
            to_remove+=("$pkg")
        fi
    done

    if [ ${#to_remove[@]} -eq 0 ]; then
        print_success "No AUR packages to remove"
        return 0
    fi

    if command_exists yay; then aur_helper="yay"
    elif command_exists paru; then aur_helper="paru"
    fi

    if [ -z "$aur_helper" ]; then
        print_error "No AUR helper available. Skipping: ${to_remove[*]}"
        return 1
    fi

    print_info "Removing ${#to_remove[@]} AUR packages via $aur_helper..."
    run "$aur_helper" -Rns --noconfirm "${to_remove[@]}"
    print_success "AUR package removal complete: ${to_remove[*]}"
}

# ============================================
# Snapshot Restoration
# ============================================
restore_snapshot() {
    print_section "System Snapshot Restoration"

    local has_snapper=false
    local has_timeshift=false

    command_exists snapper && has_snapper=true
    command_exists timeshift && has_timeshift=true

    if [ "$has_snapper" = false ] && [ "$has_timeshift" = false ]; then
        print_warning "No supported snapshot tool found (snapper/timeshift)"
        return 0
    fi

    if [ "$has_snapper" = true ]; then
        print_info "Available Snapper snapshots:"
        run_privileged snapper list
    fi

    if [ "$has_timeshift" = true ]; then
        print_info "Available Timeshift snapshots:"
        run_privileged timeshift --list
    fi

    echo ""
    print_warning "Snapshot restoration is manual. Use:"
    print_info "  snapper undochange <num>  OR  timeshift --restore --snapshot <name>"
    print_info "Run these commands manually if you want to restore a pre-install snapshot."
}

# ============================================
# Detection
# ============================================
detect_system() {
    print_header "🔍 Detecting System"

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
            cachyos)
                print_success "CachyOS detected"
                ;;
            arch|manjaro|endeavouros)
                print_warning "Arch-based distro detected"
                ;;
            *)
                print_error "This uninstaller is designed for CachyOS / Arch Linux."
                exit 1
                ;;
        esac
    else
        print_error "Cannot detect distro"
        exit 1
    fi
}

# ============================================
# Main Logic
# ============================================
main() {
    parse_args "$@"

    print_header "🗑️  Indecisius Dotfiles Uninstaller"
    echo -e "${CYAN}MangoWM-focused rice removal for CachyOS.${NC}\n"
    if [ "$DRY_RUN" -eq 1 ]; then
        print_warning "Dry-run mode: no packages/files will be changed. Use --apply to uninstall."
    fi

    if ! ask_confirmation "This will remove Indecisius dotfiles and optionally packages. Continue?"; then
        echo -e "${YELLOW}Cancelled.${NC}"
        exit 0
    fi

    detect_system

    # Snapshot restoration (if requested)
    if [ "$RESTORE_SNAPSHOT" -eq 1 ]; then
        restore_snapshot
    fi

    # Config restoration
    if [ "$RESTORE_CONFIGS" -eq 1 ]; then
        restore_configs
    fi

    # Session entry removal
    if [ "$REMOVE_SESSION" -eq 1 ]; then
        remove_session_entry
    fi

    # Package removal
    if [ "$REMOVE_PACKAGES" -eq 1 ]; then
        print_section "Removing Core Packages"

        CORE_PKGS=(
            mangowm wlr-randr
            waybar wofi cava matugen jq
            kitty fish starship zoxide fastfetch
            bat eza yazi neovim
            cliphist wl-clipboard
            grim slurp swappy
            brightnessctl pavucontrol pamixer playerctl
            networkmanager bluetui
            gnome-keyring polkit polkit-gnome
            xdg-desktop-portal xdg-desktop-portal-wlr xdg-user-dirs
            nwg-look qt5ct qt6ct gtk3 gtk4
            dbus
            wlrctl imagemagick
            ttf-jetbrains-mono-nerd ttf-font-awesome noto-fonts noto-fonts-emoji
        )
        remove_packages "${CORE_PKGS[@]}"

        # Notification daemons
        print_section "Removing Notification Daemon"
        for daemon in mako swaync dunst; do
            if package_installed "$daemon"; then
                if ask_confirmation "Remove $daemon?" "y"; then
                    remove_packages "$daemon"
                fi
            fi
        done

        # AUR packages
        if [ "$WITH_AUR" -eq 1 ]; then
            print_section "Removing Optional AUR Packages"
            AUR_PKGS=(waypaper wlogout awww swaync)
            remove_aur_packages "${AUR_PKGS[@]}"
        else
            print_info "Skipping AUR packages (use --with-aur to remove waypaper, wlogout, awww, swaync)"
        fi
    fi

    print_header "✅ Uninstallation Complete!"
    echo -e "${GREEN}Indecisius dotfiles uninstall finished.${NC}"
    echo -e "${WHITE}What was done:${NC}"
    [ "$RESTORE_CONFIGS" -eq 1 ] && echo -e "  ${CHECKMARK} Configs restored from backups"
    [ "$REMOVE_SESSION" -eq 1 ] && echo -e "  ${CHECKMARK} Mango session entry removed"
    [ "$REMOVE_PACKAGES" -eq 1 ] && echo -e "  ${CHECKMARK} Core packages removed"
    [ "$WITH_AUR" -eq 1 ] && echo -e "  ${CHECKMARK} AUR packages removed"
    [ "$RESTORE_SNAPSHOT" -eq 1 ] && echo -e "  ${INFO} Snapshot restoration info shown"
    echo -e "${WHITE}Note:${NC} User data (~/Imagens, ~/Documents, etc.) was NOT touched."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi