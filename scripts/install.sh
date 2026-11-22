#!/bin/sh
# Builds the app, replaces ~/Applications/SimpleTile.app, and relaunches it.
# Passes $SIMPLETILE_SIGN_IDENTITY through to bundle.sh.
set -eu
cd "$(dirname "$0")/.."

app="$(scripts/bundle.sh | tail -n 1)"
dest="$HOME/Applications/SimpleTile.app"

if pkill -x SimpleTile; then
    while pgrep -x SimpleTile >/dev/null; do sleep 0.1; done
fi

mkdir -p "$HOME/Applications"
rm -rf "$dest"
cp -R "$app" "$dest"
open "$dest"

echo "Installed $dest"
