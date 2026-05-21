# ---------------------------------------
# Indecisius fish config — cybr-inspired
# Inspired by cybrcore/cybr-fish by scherrer-txt (GPL-3.0):
# https://github.com/cybrcore/cybr-fish
# Adapted for this Mango setup with guarded optional integrations.
# ---------------------------------------

set -g fish_greeting ""

alias c='clear'
alias cat='bat'
alias reload='source ~/.config/fish/config.fish ; kitty @ load-config'
alias ls="eza -1h -s modified -r --icons=always --group-directories-first"
alias b='cd ..'
alias h='cd'
alias d='cd ~/Downloads'
alias pacup='sudo timeshift --create --comments "Before update" --tags O && yay -Syu'
alias paci='yay -S --needed'
alias pacr='yay -Rns'
alias logout='loginctl terminate-user $USER'
alias reboot='systemctl reboot'
alias off='systemctl poweroff'
alias suspend='systemctl suspend'
alias ff='fastfetch'
alias wifi='nmtui'
alias bt='bluetui'
alias gc='git clone'

set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERM xterm-kitty
set -gx COLORTERM truecolor
set -gx MICRO_TRUECOLOR 1
set -gx STARSHIP_CONFIG ~/.config/starship.toml

if not contains -- "$HOME/.npm-global/bin" $PATH
    set -gx PATH $HOME/.npm-global/bin $PATH
end

# cybr/lucid fish colors
set -g fish_color_autosuggestion 4D5A80
set -g fish_color_cancel F24848 --reverse
set -g fish_color_command 3051F2
set -g fish_color_comment 4D5A80
set -g fish_color_cwd 30F291
set -g fish_color_cwd_root F24848
set -g fish_color_end F24848
set -g fish_color_error F24848 --bold --background=631F21
set -g fish_color_escape 4D5A80
set -g fish_color_history_current --bold
set -g fish_color_host A130F2
set -g fish_color_host_remote A130F2
set -g fish_color_keyword A130F2
set -g fish_color_normal F24848
set -g fish_color_operator 30F291
set -g fish_color_param 29BECC
set -g fish_color_quote F2D230
set -g fish_color_redirection F24848 --bold
set -g fish_color_search_match 30F291 --bold --background=0C3423
set -g fish_color_selection 29BECC --bold --background=0B292F
set -g fish_color_status F24848
set -g fish_color_user 29BECC
set -g fish_color_valid_path --underline
set -g fish_pager_color_completion normal
set -g fish_pager_color_description yellow -i
set -g fish_pager_color_prefix normal --bold --underline
set -g fish_pager_color_progress brwhite --background=cyan
set -g fish_pager_color_selected_background -r
set -U fish_key_bindings fish_default_key_bindings

if type -q flatpak; and not set -q FLATPAK_PATHS
    set -gx FLATPAK_PATHS (flatpak --installations)
end

if type -q zoxide
    zoxide init fish | source
end

if type -q starship
    starship init fish | source
    enable_transience

    function starship_transient_prompt_func
        starship module character
    end

    function starship_transient_rprompt_func
        starship module custom.time_arrow
        starship module custom.transient_time
    end
end


# Added by Antigravity CLI installer
set -gx PATH "/home/geko/.local/bin" $PATH
