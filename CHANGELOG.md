# Changelog (Registro de Alterações)

Este documento registra o histórico de alterações e evolução das configurações do **Indecisius-dotfiles**.

---

## [1.2.0] - 2026-05-21
### Adicionado
* **Captura de Tela:** Atalho `SUPER+Print` (`Mod+Print`) reconfigurado para criar automaticamente o diretório `~/Pictures/Screenshots`, tirar um print da tela inteira, salvar o arquivo com nome dinâmico timestamped (`Screenshot_YYYY-MM-DD_HH-MM-SS.png`), disparar notificação com o nome do arquivo e emitir som de câmera. (commit `a272f57`)
* **Não Perturbe (DND):** Módulo e botão de controle interativo "Não Perturbe" na barra de status do Waybar. Integração instantânea de clique via sinal (`pkill -RTMIN+6`) e mudança de ícone/cor para indicar estado ativo (vermelho do Matugen). (commit `3c12f0c`)
* **Mako Config:** Configurado bloco `[mode=dnd]` com `invisible=1` para garantir a ocultação física das notificações quando ativo. (commit `3c12f0c`)
* **Window Management:** Atalhos `SUPER+y` e `SUPER+u` mapeados para aumentar/diminuir o número de janelas na área Master (`incnmaster`) no layout do gerenciador de janelas. (commit `fd2a64c`)
* **Compositor MangoWM:** Configurado blur nativo dinâmico desativando o modo otimizado (`blur_optimized = 0`), eliminando o efeito "xray" na interface. (commit `989312b`)
* **Automação Matugen:** Integração direta no script de geração de cores para recarregar as configurações do MangoWM automaticamente (`mmsg -s -d reload_config`). (commit `989312b`)
* **Barra (Waybar):** Propriedade `exec-on-event: true` configurada no seletor de brilho, atualizando o valor da tela em tempo real durante o scroll da roda do mouse. (commit `989312b`)

### Modificado / Refatorado
* **Scripts:** Reorganização completa e divisão de 18 scripts utilitários em subpastas semânticas: `menus/` (diálogos Wofi), `wm/` (configurações internas) e `media/` (Wallpapers, brilho e áudio). (commit `dae6e0e`)
* **Teclas de Atalho:** Migração de binds específicas de caminhos absolutos personalizados `custom/` para a pasta comum `configs/`. Consolidação do cursor e limpeza de arquivos mortos. (commit `60b0e69`)

---

## [1.1.0] - 2026-05-20
### Modificado / Refatorado
* **Renomeação:** Renomeado o diretório principal do gerenciador de janelas `hyprmango` para `configs`. (commit `c65b178`)
* **Wofi & Wlogout:** Migração completa e substituição de menus antigos do `rofi` em prol do `wofi` e `wlogout` com temas customizados Catppuccin. (commit `f5c1672`)
* **Documentação:** README atualizado com galerias de capturas de tela e créditos. (commit `6a98d5d`, `ca533a7`, `3be81fb`)

---

## [1.0.0] - 2026-05-19
### Adicionado
* **Shell:** Adicionado suporte e arquivos de configuração para `fish` shell e prompt `starship`. (commit `72efd23`)
* **Instalador Resiliente:** Scripts de instalação refinados para snapshots automáticos pré-instalação e hardening de instalação de pacotes AUR. (commit `66ed16a`, `a7b983a`, `7d33c2d`)

---

## [0.9.0] - 2026-05-16
### Adicionado
* **Menu do Waybar:** Mapeado botão `SUPER+R` para recarregar o MangoWM e reiniciar a barra do Waybar. (commit `d0f2cdf`)
* **Mapeamento do Scroller:** Atalho `SUPER+comma` para alternar o modo centralizado do scroller. (commit `ceeeaa6`)
* **Barra de Tarefas:** Adicionada pílula de janelas minimizadas no Waybar via `wlr/taskbar`. (commit `ae7bd3f`)
* **Brilho Externo:** Adicionado suporte a controle de brilho via DDC/CI para monitores externos. (commit `d0541ce`)
* **Área de Transferência:** Menu gráfico modernizado para gerenciamento do clipboard. (commit `34baf42`)
* **Instalador Universal:** Script de instalação completo para sistemas Arch Linux barebones. (commit `7537a71`)
* **Papel de Parede (awww):** Transição de wallpaper migrada do `swaybg` para o daemon `awww` com transições aleatórias estáveis. (commit `ed72f33`)

---

## [0.1.0] - 2026-05-16
* **Commit Inicial:** Importação dos dotfiles base e configurações do Mango WM. (commit `bd3e57d`)
