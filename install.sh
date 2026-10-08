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

echo "installed to $dest"
echo "launcher: $bindir/hyprtk-bar-qt  (or: qs -c hyprtk-bar-qt)"
