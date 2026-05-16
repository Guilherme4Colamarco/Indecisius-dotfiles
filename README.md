# Mango WM Dotfiles

> Minimal rice for CachyOS using Mango (Hyprland wrapper).

## Sobre

Este repositório contém as configurações de desktop para **CachyOS** com foco exclusivo no **Mango WM** e seu ecossistema.

## Stack

| Componente | Ferramenta |
|---|---|
| **WM** | [Mango](https://github.com/CachyOS/mangowm) (wrapper do Hyprland) |
| **Barra** | [Waybar](https://github.com/Alexays/Waybar) (tema Tokyo Night) |
| **Launcher** | [Rofi](https://github.com/davatorium/rofi) (wayland fork) |
| **Notificações** | [Mako](https://github.com/emersion/mako) |
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| **Shell** | [Fish](https://fishshell.com/) com emoji-powerline |
| **Clipboard** | [cliphist](https://github.com/sentriz/cliphist) |
| **Wallpaper** | [awww](https://codeberg.org/LGFae/awww) (sucessor do swww) + [waypaper](https://github.com/anufrievroman/waypaper) |
| **Screenshots** | [grim](https://sr.ht/~emersion/grim/) + [slurp](https://github.com/emersion/slurp) + [swappy](https://github.com/jtheoof/swappy) |
| **Power Menu** | [wlogout](https://github.com/ArtsyMacaw/wlogout) |
| **Color Scheme** | Tokyo Night (estático, matugen desabilitado) |

## Estrutura

```
.
├── .config/
│   ├── mango/              # Configuração do Mango WM
│   │   ├── hyprmango/      # Módulos core (execs, keybinds, colors, etc.)
│   │   └── scripts/        # Scripts auxiliares
│   ├── waybar/MangoWC/     # Config e CSS da Waybar
│   ├── kitty/              # Terminal config
│   ├── fastfetch/          # System info display
│   ├── fish/functions/     # Fish prompt (emoji-powerline)
│   ├── mako/               # Notificações
│   ├── rofi/               # Temas do Rofi
│   ├── wlogout/            # Layout e style do power menu
│   └── waypaper/           # Config do seletor de wallpaper
└── .kimi/                  # Config do Kimi CLI
```

## Keybinds principais

| Atalho | Ação |
|---|---|
| `SUPER + d` | Rofi app launcher |
| `SUPER + /` | Rofi app launcher (alternativo) |
| `SUPER + `` ` | Rofi switcher de janelas |
| `SUPER + BackSpace` | Wlogout (power menu) |
| `SUPER + B` | Toggle Waybar |
| `SUPER + V` | Clipboard history (cliphist + rofi) |
| `SUPER + Shift + .` | Emoji picker |
| `SUPER + Tab` | Mango overview |
| `SUPER + Shift + S` | Screenshot area → swappy |

## Instalação Rápida (Automática)

```bash
git clone https://github.com/<seu-user>/mango-dotfiles.git
cd mango-dotfiles
./install.sh
```

O instalador é feito para **CachyOS / Arch Linux** e instala o ecossistema completo do Mango WM.

## Instalação Manual

```bash
# Copiar configs para ~/.config/
cp -r .config/* ~/.config/
# ou stow / chezmoi / symlink
```

## Dependências

| Pacote | Função |
|---|---|
| `mangowm` | Window Manager |
| `waybar` | Barra superior |
| `rofi` / `rofi-wayland` | Launcher |
| `mako` | Notificações |
| `kitty` | Terminal |
| `fish` | Shell |
| `awww` | Wallpaper daemon |
| `waypaper` | GUI de wallpapers |
| `cliphist` | Histórico de clipboard |
| `grim` + `slurp` + `swappy` | Screenshots |
| `wlogout` | Power menu |
| `brightnessctl` | Brilho da tela |
| `wl-clipboard` | Clipboard Wayland |

## Créditos

## Créditos

- **CachyOS** community pelas configs base e repo packages
- **Tokyo Night** color palette por [Enkia](https://github.com/enkia/tokyo-night-vscode-theme)
