#!/usr/bin/env python3
"""
mango-dock — Minimal GTK3 layer-shell dock for MangoWM.

Pinned-apps bar + Wofi launcher. Auto-writes default config when none exists.
"""

import os, sys, signal, subprocess, shlex

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import Gtk, GLib, Gdk, GdkPixbuf, GtkLayerShell

HOME       = os.path.expanduser('~')
CONFIG_DIR = os.path.join(HOME, '.config',  'mango', 'dock')
PINNED     = os.path.join(CONFIG_DIR, 'pinned.conf')
STYLE_FILE = os.path.join(CONFIG_DIR, 'style.css')
ICON_DIRS  = [os.path.join(HOME, '.local', 'share', 'icons'),
              '/usr/share/icons', '/usr/share/pixmaps']
APPL_DIRS  = [os.path.join(HOME, '.local', 'share', 'applications'),
              '/usr/share/applications']

DEBUG = '--debug' in sys.argv

def log(tag, *a):
    if tag == 'D' and not DEBUG: return
    print(f'[mangodock:{tag}]', *a)

logi = lambda *a: log('I', *a)
logd = lambda *a: log('D', *a)

# ══════════════════════════════════════════════════════════════════════════════
# Icon helpers
# ══════════════════════════════════════════════════════════════════════════════

def _find_icon(name: str):
    """Resolve icon name → path. Exact match first, then prefix fallback."""
    if not name: return ''
    for d in ICON_DIRS:
        if not os.path.isdir(d): continue
        for root, _, fs in os.walk(d):
            for f in sorted(fs):
                b = os.path.splitext(f)[0]
                if b == name: return os.path.join(root, f)
    for d in ICON_DIRS:
        if not os.path.isdir(d): continue
        for root, _, fs in os.walk(d):
            for f in sorted(fs):
                b = os.path.splitext(f)[0]
                if b.startswith(name + '-') or b == name:
                    return os.path.join(root, f)
    return ''

def _exec_basename(exec_str: str) -> str:
    try:
        return shlex.split(exec_str, posix=False)[0].lower().lstrip('./')
    except Exception:
        return exec_str.strip().split()[0].lower()

def _desktop_for(cmd: str):
    """Return .desktop path whose Exec= basename matches cmd (case-insensitive)."""
    if not cmd: return None
    want = cmd.lower()
    for d in APPL_DIRS:
        if not os.path.isdir(d): continue
        for f in sorted(os.listdir(d)):
            if not f.endswith('.desktop'): continue
            p = os.path.join(d, f)
            try:
                with open(p, errors='replace') as fh:
                    for line in fh:
                        ls = line.strip()
                        if not ls.startswith('Exec='): continue
                        if _exec_basename(ls.split('=', 1)[1]) == want:
                            return p
            except OSError: continue
    return None

def _icon_from_desktop(dpath):
    if not dpath or not os.path.isfile(dpath): return ''
    try:
        for line in open(dpath, errors='replace'):
            if line.strip().startswith('Icon='):
                val = line.split('=', 1)[1].strip()
                return val if val.endswith(('.png','.svg','.xpm','.ico')) else _find_icon(val) or ''
    except OSError: pass
    return ''

def icon_for(label, cmd):
    label = label or ''; cmd = cmd or label
    dpath = _desktop_for(cmd) or _desktop_for(label)
    return _icon_from_desktop(dpath) if dpath else (_find_icon(label) or '')

# ══════════════════════════════════════════════════════════════════════════════
# Default pins + style (written on first run)
# ══════════════════════════════════════════════════════════════════════════════

def _write_defaults():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    if not os.path.isfile(STYLE_FILE):
        with open(STYLE_FILE, 'w') as f:
            f.write(DEFAULT_CSS)
    if not os.path.isfile(PINNED):
        with open(PINNED, 'w') as f:
            f.write('# mangodock — Label | command | icon-name\n\n')
            for l, c, i in DEFAULT_PINS:
                f.write(f'{l} | {c} | {i}\n')

DEFAULT_PINS = [
    ('Kitty',     'kitty',    'utilities-terminal'),
    ('Dolphin',   'dolphin',  'system-file-manager'),
    ('Firefox',   'firefox',  'firefox'),
    ('Mango Lk.', 'nwg-look', 'preferences-desktop-theme'),
    ('Waybar',    'waybar',   'utilities-terminal'),
    ('Git',       'git',      'git-gui'),
]

DEFAULT_CSS = """\
window        { background: rgba(20, 17, 14, 0.92); }
eventbox      { padding: 4px 10px; border-radius: 8px; }
eventbox:hover{ background: rgba(210, 180, 140, 0.30); border-radius: 10px; }
eventbox label{ color: #E8D5C0; font-size: 9pt; }
eventbox:hover label { color: #FFF8EE; }
"""

# ══════════════════════════════════════════════════════════════════════════════
# Config loader
# ══════════════════════════════════════════════════════════════════════════════

def load_pinned():
    items = []
    try:
        with open(PINNED) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'): continue
                p = line.split('|', 2)
                label      = p[0].strip()
                cmd        = p[1].strip()
                icon_name  = p[2].strip() if len(p) > 2 else ''
                items.append({'label': label, 'cmd': cmd,
                              'icon_name': icon_name,
                              'icon_path': icon_for(label, cmd) or
                                           'utilities-terminal'})
    except FileNotFoundError:
        pass
    return items

# ══════════════════════════════════════════════════════════════════════════════
# Dock window (plain Gtk.Window + GLib.MainLoop — no GApplication boilerplate)
# ══════════════════════════════════════════════════════════════════════════════

ICON_PX   = 52
LAUNCHER  = '\u25B8'   # ► wofi launcher button

class DockButton(Gtk.EventBox):
    """One pinned-app button."""
    def __init__(self, item):
        super().__init__()
        self.item  = item
        self.label_py  = item['label']

        vb = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1,
                     halign=Gtk.Align.CENTER)
        self.add(vb)

        ip = item.get('icon_path', '')
        if os.path.isfile(ip):
            pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                ip, width=ICON_PX, height=ICON_PX, preserve_aspect_ratio=True)
            icn = Gtk.Image.new_from_pixbuf(pb)
        else:
            icn = Gtk.Label.new('\u2022')         # bullet fallback
            icn.get_style_context().add_class('no-icon')
        icn.set_pixel_size(ICON_PX)
        vb.pack_start(icn, False, False, 0)

        lbl = Gtk.Label.new(item.get('label', '?'))
        lbl.set_ellipsize(3)           # PANGO_ELLIPSIZE_END
        lbl.set_max_width_chars(10)
        vb.pack_start(lbl, False, False, 0)

        self.connect('button-press-event', _on_click, item)


def _on_click(_eb, event, item):
    if   event.button == 1:   # left → wofi run
        _wofi_run(cmd_fmt=item.get('cmd', ''))
    elif event.button == 2:   # middle → pkill
        cmd = item.get('cmd', '').split()[0]
        if cmd: subprocess.Popen(['pkill','-x',cmd], close_fds=True)
    return True

WOFI_ARGS = ['wofi', '--show', 'run',
             '--conf', os.path.join(HOME, '.config', 'wofi', 'spotlight.conf'),
             '--no-actions']

def _wofi_run(*, cmd_fmt=''):
    subprocess.Popen(WOFI_ARGS + ([cmd_fmt] if cmd_fmt else []),
                     close_fds=True)


def open_dock():
    load_css()
    write_win()
    loop.run()

# ══════════════════════════════════════════════════════════════════════════════
# Main loop
# ══════════════════════════════════════════════════════════════════════════════

loop  : GLib.MainLoop  = GLib.MainLoop()
win   : Gtk.Window     = None

def load_css():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    css = DEFAULT_CSS
    if os.path.isfile(STYLE_FILE):
        try:
            with open(STYLE_FILE) as f: css = f.read()
        except OSError: pass
    else:
        with open(STYLE_FILE, 'w') as f:
            f.write(css)
    p = Gtk.CssProvider()
    p.load_from_data(css.encode())
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    logi('css loaded')

def write_win():
    global win
    win = Gtk.Window(decorated=False,
                     skip_pager_hint=True, skip_taskbar_hint=True,
                     resizable=False,
                     type_hint=Gtk.WindowTypeHint.DOCK)
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_namespace(win, 'mangodock')
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.BOTTOM, True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.LEFT,   True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP,    False)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.RIGHT,  False)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.BOTTOM)
    GtkLayerShell.set_keyboard_interactivity(win, False)
    try:
        GtkLayerShell.set_monitor(win, Gdk.Display.get_default().get_primary_monitor())
    except Exception: pass

    root = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=3)
    root.set_margin_start(8); root.set_margin_end(8)
    root.set_margin_top(3);  root.set_margin_bottom(3)
    win.add(root)

    # pinned buttons (left → right)
    pinned = load_pinned()
    for item in pinned:
        btn = DockButton(item)
        root.pack_start(btn, False, False, 0)

    # wofi launcher → rightmost
    launcher = Gtk.EventBox()
    lbl = Gtk.Label.new(LAUNCHER)
    lbl.set_halign(Gtk.Align.CENTER)
    launcher.add(lbl)
    launcher.connect('button-press-event',
                     lambda _eb, _ev: _wofi_run() or True)
    root.pack_end(launcher, False, False, 0)

    win.connect('destroy', lambda *_: loop.quit())
    win.show_all()
    logi(f'opened  pinned={len(pinned)}')

# ══════════════════════════════════════════════════════════════════════════════
# Signal → quit
# ══════════════════════════════════════════════════════════════════════════════

def _sig_quit(*_a):
    logi('signal → quit')
    GLib.idle_add(loop.quit)

signal.signal(signal.SIGTERM, _sig_quit)
signal.signal(signal.SIGINT,  _sig_quit)

# ══════════════════════════════════════════════════════════════════════════════
def main():
    logi('start', f'python {sys.version.split()[0]}')
    _write_defaults()
    open_dock()

if __name__ == '__main__':
    main()
