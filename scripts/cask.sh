#!/bin/sh
# Prints the Homebrew cask for a release: scripts/cask.sh VERSION SHA256
set -eu

version="$1"
sha256="$2"

cat <<CASK
cask "simpletile" do
  version "$version"
  sha256 "$sha256"

  url "https://github.com/BlazejNowicki/simpletile/releases/download/v#{version}/SimpleTile-#{version}.zip"
  name "SimpleTile"
  desc "Keyboard window tiling and a per-window switcher"
  homepage "https://github.com/BlazejNowicki/simpletile"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "SimpleTile.app"

  # The app is self-signed, not notarized: without this, Gatekeeper blocks the first launch.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-d", "com.apple.quarantine", "{{appdir}}/SimpleTile.app"], must_succeed: false
  end

  uninstall quit: "io.github.blazejnowicki.simpletile"
end
CASK
