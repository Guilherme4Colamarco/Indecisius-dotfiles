# Indecisius Dotfiles

> Desktop rice para CachyOS com MangoWM, Waybar, Wofi, Cava, matugen e aparência controlada pelo nwg-look.

## Sobre

Este repositório guarda a configuração atual do meu ambiente Wayland no **CachyOS**, com foco em **MangoWM** como compositor principal. A ideia é manter o setup modular, fácil de restaurar e simples de ajustar no dia a dia.

O fluxo atual evita launchers/painéis antigos e centraliza o visual em três pontos:

- `matugen` para cores derivadas do wallpaper
- `nwg-look` para tema GTK, fonte e cursor
- `wofi` como launcher principal em modo spotlight

## Stack

| Componente | Ferramenta |
|---|---|
| **WM** | [MangoWM](https://github.com/CachyOS/mangowm) |
| **Barra** | [Waybar](https://github.com/Alexays/Waybar) com tema MangoWC + powerline SVG |
| **Launcher** | [Wofi](https://hg.sr.ht/~scoopta/wofi) em modo `drun` spotlight |
| **Switcher/menus auxiliares** | [Wofi](https://hg.sr.ht/~scoopta/wofi) em modo `dmenu` |
| **Cores dinâmicas** | [matugen](https://github.com/InioX/matugen) |
| **Visualizador de áudio** | [Cava](https://github.com/karlstav/cava) com cores do matugen |
| **Aparência GTK/cursor/fontes** | [nwg-look](https://github.com/nwg-piotr/nwg-look), GTK 2/3/4, Qt5/Qt6 e XCursor |
| **Notificações** | [Mako](https://github.com/emersion/mako) |
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| **Shell** | [Fish](https://fishshell.com/) + Starship |
| **Clipboard** | [cliphist](https://github.com/sentriz/cliphist) + Wofi |
| **Wallpaper** | [awww](https://codeberg.org/LGFae/awww) + [waypaper](https://github.com/anufrievroman/waypaper) |
| **Screenshots** | [grim](https://sr.ht/~emersion/grim/) + [slurp](https://github.com/emersion/slurp) + [swappy](https://github.com/jtheoof/swappy) |
| **Power menu** | [wlogout](https://github.com/ArtsyMacaw/wlogout) |

## Estrutura

```text
.
├── .config/
│   ├── mango/
│   │   ├── config.conf              # arquivo principal, só orquestra sources
│   │   ├── hyprmango/               # módulos core: env, execs, layout, colors, keybinds
│   │   ├── custom/                  # overrides pessoais carregados por último
│   │   └── scripts/                 # reload, wallpaper, matugen, nwg-look, menus
│   ├── waybar/
│   │   ├── MangoWC/                 # config, CSS, matugen.css e SVGs powerline
│   │   └── Modules/                 # módulos separados da Waybar
│   ├── wofi/                        # spotlight, layout menu e estilos Wofi
│   ├── cava/                        # visualizador de áudio com cores geradas pelo matugen
│   ├── gtk-3.0/                     # settings exportados pelo nwg-look
│   ├── gtk-4.0/                     # settings sincronizados pelo wrapper nwg-look
│   ├── qt5ct/                       # fonte/ícones espelhados do nwg-look
│   ├── qt6ct/                       # fonte/ícones espelhados do nwg-look
│   ├── kitty/                       # terminal
│   ├── fish/                        # shell e prompt
│   ├── mako/                        # notificações
│   ├── wlogout/                     # power menu
│   └── waypaper/                    # GUI de wallpapers
├── .icons/default/index.theme       # cursor padrão para XCursor
├── .local/share/applications/       # atalhos locais, incluindo nwg-look sincronizado
└── install.sh                       # instalador dry-run por padrão
```

## Keybinds Principais

| Atalho | Ação |
|---|---|
| `SUPER + D` | Abre o Wofi spotlight (`drun`) |
| `SUPER + Space` | Abre o Wofi spotlight (`drun`) |
| `SUPER + grave` | Overview do Mango |
| `SUPER + Shift + D` | Wofi run menu |
| `SUPER + Return` | Kitty |
| `SUPER + Q` | Fecha a janela focada |
| `SUPER + V` | Histórico de clipboard |
| `SUPER + Shift + .` | Emoji picker |
| `SUPER + Shift + A` | Abre `nwg-look` e sincroniza GTK/cursor/fontes ao fechar |
| `SUPER + R` | Recarrega Mango e Waybar |
| `SUPER + B` | Toggle/reload da Waybar |
| `SUPER + Tab` | Overview do Mango |
| `SUPER + O` | Overview do Mango |
| `SUPER + N` | Menu de layouts |
| `SUPER + comma` | Alterna centralização do scroller |
| `SUPER + W` | Wallpaper aleatório + atualização matugen |
| `SUPER + Shift + W` | Abre Waypaper |
| `SUPER + Shift + S` | Screenshot de área para clipboard |
| `SUPER + Shift + R` | Screenshot de área para arquivo |
| `SUPER + 1..9` | Troca para a tag/workspace |
| `SUPER + Shift + 1..9` | Move janela para a tag/workspace |

Na Waybar, o scroll sobre a área de workspaces também troca tag/workspace:

- Scroll para cima: workspace anterior
- Scroll para baixo: próximo workspace

## Launcher

O launcher principal é o Wofi em modo `drun`:

```bash
wofi --show drun --conf ~/.config/wofi/spotlight.conf --no-actions
```

O arquivo `~/.config/wofi/spotlight.conf` usa:

```ini
matching=fuzzy
insensitive=true
drun-ignore_metadata=true
```

Isso faz a busca ser fuzzy e case-insensitive, mas evita priorizar apps só porque a descrição deles menciona o termo pesquisado. Exemplo: pesquisar `arquivos` deve priorizar o Nautilus/Arquivos, não editores que apenas dizem “edite arquivos de texto”.

O antigo launchpad foi removido.

## Aparência

### Matugen

O script `~/.config/mango/scripts/update-matugen-accent.sh` extrai cores do wallpaper atual e atualiza:

- `~/.config/mango/hyprmango/colors.matugen.conf`
- `~/.config/waybar/MangoWC/matugen.css`
- SVGs powerline da Waybar em `~/.config/waybar/MangoWC/svg/`
- `~/.config/wofi/matugen.css`
- `~/.config/cava/config`
- cores do Fish/Starship quando aplicável

Os scripts de wallpaper chamam essa atualização automaticamente.

### nwg-look

O wrapper `~/.config/mango/scripts/nwg-look-sync.sh` deixa tema GTK, cursor e fontes mais fáceis de controlar pelo `nwg-look`.

Fluxo recomendado:

```bash
~/.config/mango/scripts/nwg-look-sync.sh --open
```

Ou use o atalho:

```text
SUPER + Shift + A
```

Ao fechar o `nwg-look`, o wrapper sincroniza:

- GTK 3: `~/.config/gtk-3.0/settings.ini`
- GTK 4: `~/.config/gtk-4.0/settings.ini`
- GTK 2: `~/.config/gtkrc-2.0`
- XCursor: `~/.icons/default/index.theme`
- Mango: `~/.config/mango/custom/nwg-look-env.conf` e `nwg-look-mango.conf`
- GSettings: `org.gnome.desktop.interface`
- Qt: fonte e ícones em `qt5ct` e `qt6ct`

## Instalação

O instalador é feito para CachyOS/Arch Linux e roda em modo seguro por padrão.

```bash
git clone <repo-url> Indecisius-dotfiles
cd Indecisius-dotfiles
./install.sh
```

O comando acima é dry-run. Para aplicar de verdade:

```bash
./install.sh --apply
```

Para permitir instalação/bootstrap de pacotes AUR:

```bash
./install.sh --apply --with-aur
```

## Instalação Manual

```bash
mkdir -p ~/.config ~/.icons ~/.local/share/applications
cp -r .config/. ~/.config/
cp -r .icons/. ~/.icons/
cp -r .local/share/applications/. ~/.local/share/applications/
```

Depois, instale a sessão local do Mango se quiser garantir que o display manager use esta árvore de configuração:

```bash
mkdir -p ~/.local/share/wayland-sessions
cp ~/.config/mango/mango.desktop ~/.local/share/wayland-sessions/
```

## Dependências

| Pacote | Função |
|---|---|
| `mangowm` | Window manager |
| `waybar` | Barra superior |
| `wofi` | Launcher principal |
| `wofi` | Launcher e menus auxiliares |
| `matugen` + `jq` | Cores dinâmicas do wallpaper |
| `cava` | Visualizador de áudio no terminal |
| `nwg-look` | Tema GTK, fontes e cursor |
| `qt5ct` + `qt6ct` | Ajustes de aparência para apps Qt |
| `mako` | Notificações |
| `kitty` | Terminal |
| `fish` + `starship` + `zoxide` | Shell |
| `awww` | Wallpaper daemon |
| `waypaper` | GUI para wallpapers |
| `cliphist` + `wl-clipboard` | Histórico e integração de clipboard |
| `grim` + `slurp` + `swappy` | Screenshots |
| `wlogout` | Power menu |
| `brightnessctl` | Brilho de tela |
| `gnome-keyring` + `polkit` | Segredos e autenticação |
| `xdg-desktop-portal` + `xdg-desktop-portal-wlr` | Portais Wayland |

## Notas

- `~/.config/mango/config.conf` carrega módulos core primeiro e depois overrides em `~/.config/mango/custom/`.
- Arquivos gerados por matugen/nwg-look são versionados aqui como referência do estado atual, mas devem ser alterados pelas ferramentas, não manualmente.
- O diretório `~/.config/mango/backups/` não faz parte do fluxo principal.

## Créditos

- Comunidade CachyOS pelos pacotes e integração do MangoWM
- Projeto MangoWM pelo compositor
- Waybar, Wofi, Mako, matugen e demais ferramentas livres usadas no setup
