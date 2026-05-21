# Inspirações e créditos

## cybrdots / cybr-waybar

- Projeto: <https://github.com/cybrcore/cybrdots>
- Waybar: <https://github.com/cybrcore/cybr-waybar>
- Autor indicado nos arquivos: `scherrer-txt`
- Licença indicada no projeto principal: GPL-3.0
- Licença indicada nos headers da Waybar: GPL-3.0

### O que vale estudar/adaptar

- Barra modular com `config.jsonc` + `modules.jsonc`.
- Separadores visuais por módulos `custom/arrow-*` usando SVGs.
- Estética angular/powerline em vez de pills arredondadas.
- Classes dinâmicas em `custom/brightness`: `max`, `high`, `mid`, `low`, `min`.
- Brightness via DDC/CI com lock/cache e refresh por sinal Waybar.
- Organização explícita de créditos no topo dos arquivos.

### Cuidados

- Não copiar blocos inteiros sem manter crédito e licença compatível.
- Se algum CSS/script for copiado de forma substancial, manter header de origem e GPL-3.0.
- Preferir adaptar ideias visuais para o tema atual do Indecisius em vez de colar a implementação inteira.
- O `cybr-waybar` é Hyprland-oriented (`hyprland/workspaces`, `hyprland/window`, scripts em `~/.config/hypr`); adaptar para Mango antes de usar.

### Crédito sugerido no README

```md
- [cybrcore/cybr-waybar](https://github.com/cybrcore/cybr-waybar) by scherrer-txt — inspiração para a estrutura visual da Waybar, separadores angulares e padrões de módulos custom.
```

## cybr-fish / cybr-starship

- Fish: <https://github.com/cybrcore/cybr-fish>
- Starship prompt: <https://github.com/cybrcore/cybr-starship>
- Autor indicado nos arquivos: `scherrer-txt`
- Licença indicada nos headers: GPL-3.0

### O que foi adaptado

- Paleta `cybr/lucid` para syntax highlighting do Fish.
- Inicialização do Starship com transience, guardada por `type -q starship`.
- Prompt powerline do `cybr-starship`, adaptado para `~/.config/starship.toml`.

### Crédito sugerido no README

```md
- [cybrcore/cybr-fish](https://github.com/cybrcore/cybr-fish) e [cybrcore/cybr-starship](https://github.com/cybrcore/cybr-starship) by scherrer-txt — inspiração/adaptação da paleta Fish e prompt Starship.
```
