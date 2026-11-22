#!/bin/sh
# Zips build/SimpleTile.app into build/SimpleTile-$VERSION.zip and prints the zip path and its sha256.
# ditto keeps the bundle's signature and extended attributes intact, which plain zip may not.
set -eu
cd "$(dirname "$0")/.."

: "${VERSION:?set VERSION, for example VERSION=0.1.0}"
zip="build/SimpleTile-$VERSION.zip"
rm -f "$zip"
ditto -c -k --keepParent build/SimpleTile.app "$zip"
echo "$zip"
shasum -a 256 "$zip" | cut -d ' ' -f 1
