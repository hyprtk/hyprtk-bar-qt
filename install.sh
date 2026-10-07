#!/usr/bin/env bash
# Install hyprtk-bar-qt: copy the QML shell into the Quickshell config dir and
# expose the launcher. The Python backend runs in place, so no venv is needed.
set -euo pipefail

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
dest="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/hyprtk-bar-qt"
bindir="$HOME/.local/bin"

mkdir -p "$dest" "$bindir"

if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete \
        --exclude '.git' --exclude '__pycache__' --exclude '*.egg-info' \
        --exclude '/build' --exclude '/dist' \
        "$here/" "$dest/"
else
    mkdir -p "$dest/bar/modules" "$dest/theme" "$dest/backend/hyprtk_bar_qt" "$dest/bin"
    cp "$here/shell.qml" "$dest/"
    cp "$here"/bar/*.qml "$dest/bar/"
    cp "$here"/bar/modules/*.qml "$dest/bar/modules/"
    cp "$here"/theme/* "$dest/theme/"
    cp "$here"/backend/hyprtk_bar_qt/*.py "$dest/backend/hyprtk_bar_qt/"
    cp "$here/bin/hyprtk-bar-qt" "$dest/bin/"
fi

chmod +x "$dest/bin/hyprtk-bar-qt"
ln -sf "$dest/bin/hyprtk-bar-qt" "$bindir/hyprtk-bar-qt"

echo "installed to $dest"
echo "launcher: $bindir/hyprtk-bar-qt  (or: qs -c hyprtk-bar-qt)"
