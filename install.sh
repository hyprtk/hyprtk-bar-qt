#!/usr/bin/env bash
# Install hyprtk-bar-qt: copy the QML shell into the Quickshell config dir and
# expose the launcher (and hotkey helpers). The Python backend runs in place,
# so no venv is needed.
set -euo pipefail

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
dest="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/hyprtk-bar-qt"
bindir="$HOME/.local/bin"

# Runtime tree the shell needs at run time.
dirs=(bar surface components config data state theme backend bin)

mkdir -p "$dest" "$bindir"

if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete \
        --exclude '.git' --exclude '__pycache__' --exclude '*.egg-info' \
        --exclude '/build' --exclude '/dist' \
        "$here/" "$dest/"
else
    cp "$here/shell.qml" "$dest/"
    for d in "${dirs[@]}"; do
        mkdir -p "$dest/$d"
        cp -a "$here/$d/." "$dest/$d/"
    done
    find "$dest" -type d -name __pycache__ -prune -exec rm -rf {} +
fi

# Expose every helper (launcher + hotkey toggles + widget-move) on PATH.
for s in "$dest"/bin/*; do
    chmod +x "$s"
    ln -sf "$s" "$bindir/$(basename "$s")"
done

# ── The Qt bar's own runtime tree (fully separate from the GTK bar) ──────
# Scripts + rofi config it runs, e.g. appsmenu.sh / updatewal-awww.sh /
# change-icons.sh / wallpaper-colors.sh / updates.sh / sync-rofi-theme.sh.
scripts_dest="$HOME/.local/share/hyprtk-bar-qt/scripts"
mkdir -p "$scripts_dest"
rm -rf "$scripts_dest"
cp -a "$here/scripts" "$scripts_dest"
chmod +x "$scripts_dest"/*.sh 2>/dev/null || true

# Shipped bar themes + clock widget themes (never clobber existing files, so a
# user's imported themes / edits survive re-installs).
themes_dest="${XDG_CONFIG_HOME:-$HOME/.config}/hyprtk-bar-qt/themes"
wt_dest="${XDG_CONFIG_HOME:-$HOME/.config}/hyprtk-bar-qt/widget-themes/clock"
mkdir -p "$themes_dest" "$wt_dest"
cp -a -n "$here/themes/." "$themes_dest/" 2>/dev/null || true
cp -a -n "$here/assets/widgets/clock/." "$wt_dest/" 2>/dev/null || true

# Migrate the Qt bar's own config from the GTK bar's config (full copy + any
# Qt-only overrides), so an existing setup carries over before the two diverge.
python3 "$here/backend/hyprtk_bar_qt/paths.py" >/dev/null 2>&1 || true

# Re-point any hyprtk-bar script paths in the Qt config at the Qt tree.
python3 - "$HOME/.config/hyprtk-bar-qt/config.json" <<'PY' || true
import json, sys
p = sys.argv[1]
try:
    d = json.load(open(p))
except Exception:
    sys.exit(0)
def fix(s):
    return s.replace("/.local/share/hyprtk-bar/scripts",
                     "/.local/share/hyprtk-bar-qt/scripts") if isinstance(s, str) else s
changed = False
for l in (d.get("quicklinks", {}) or {}).get("links", []) or []:
    for k in ("command", "command_right", "command_middle"):
        if isinstance(l.get(k), str) and "/hyprtk-bar/scripts" in l[k]:
            l[k] = fix(l[k]); changed = True
    # The wallpaper quicklink opens the themer; label it "Theme Manager".
    if l.get("id") == "wallpaper" and l.get("label") == "Wallpaper":
        l["label"] = "Theme Manager"; changed = True
u = d.get("updates", {}) or {}
for k in ("script", "install_command"):
    if isinstance(u.get(k), str) and "/hyprtk-bar/scripts" in u[k]:
        u[k] = fix(u[k]); changed = True
if changed:
    json.dump(d, open(p, "w"), indent=2)
PY

# Pre-build the wallpaper thumbnail cache so the Theme Manager opens with every
# thumbnail visible instantly instead of decoding full-resolution images.
wall_dir="$(python3 - <<'PY'
import json, os
p = os.path.expanduser("~/.config/hyprtk-bar-qt/config.json")
try:
    d = json.load(open(p))
except Exception:
    d = {}
print(d.get("wallpaperDir") or os.path.expanduser("~/Pictures/Wallpapers"))
PY
)"
if [ -d "$wall_dir" ]; then
    echo "building wallpaper thumbnail cache for $wall_dir …"
    python3 "$here/backend/hyprtk_bar_qt/wallpapers.py" build-thumbs "$wall_dir" >/dev/null 2>&1 || true
fi

echo "installed to $dest"
echo "scripts:  $scripts_dest"
echo "launcher: $bindir/hyprtk-bar-qt  (or: qs -c hyprtk-bar-qt)"
