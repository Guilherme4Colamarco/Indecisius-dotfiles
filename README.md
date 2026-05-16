# Indecisius Dotfiles

> Dotfiles indecisos — porque decidir é difícil, então troca tudo até funcionar.

## Sobre

Este repositório contém as configurações pessoais de desktop para CachyOS, migradas do setup [Event Horizon](https://github.com/ Western-Stock2454/Event-Horizon-Dotfiles) (baseado em Quickshell) para um rice tradicional usando **Mango WM + Waybar + Rofi + Mako**.

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
│   └── EventHorizon/       # Settings (matugen desligado)
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

## Instalação

```bash
# Clone
gh repo clone <seu-user>/Indecisius-dotfiles ~/.config
# ou manualmente copie cada pasta para ~/.config/
```

> ⚠️ Requer: `mangowm`, `waybar`, `rofi-wayland`, `mako`, `kitty`, `fish`, `cliphist`, `grim`, `slurp`, `swappy`, `wlogout`, `brightnessctl`, `wl-clipboard`

## Créditos

- Event Horizon dotfiles (base original)
- Tokyo Night color palette
- CachyOS community
