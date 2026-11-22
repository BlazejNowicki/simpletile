#!/bin/sh
# Builds build/SimpleTile.app.
# Signs with $SIMPLETILE_SIGN_IDENTITY when set. Ad-hoc signing (the default) makes macOS ask for the
# Accessibility permission again after every rebuild; a self-signed code signing certificate avoids that.
set -eu
cd "$(dirname "$0")/.."

swift build -c release --product SimpleTile
bin="$(swift build -c release --show-bin-path)/SimpleTile"

app=build/SimpleTile.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin" "$app/Contents/MacOS/SimpleTile"
cp Resources/Info.plist "$app/Contents/Info.plist"

iconset="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$iconset" "$app/Contents/Resources"
for size in 16 32 128 256 512; do
    sips -z $size $size Resources/AppIcon.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) Resources/AppIcon.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
codesign --force --sign "${SIMPLETILE_SIGN_IDENTITY:--}" "$app"

echo "$app"
