#!/bin/sh
# Fails if line coverage of Sources/SimpleTileCore is below $1 percent (default 90).
# Run after `swift test --enable-code-coverage`.
set -eu
cd "$(dirname "$0")/.."

python3 -I - "$(swift test --show-codecov-path)" "${1:-90}" <<'PY'
import json, sys

report, minimum = sys.argv[1], float(sys.argv[2])
files = [f for f in json.load(open(report))["data"][0]["files"] if "/Sources/SimpleTileCore/" in f["filename"]]
covered = sum(f["summary"]["lines"]["covered"] for f in files)
total = sum(f["summary"]["lines"]["count"] for f in files)
percent = 100 * covered / total
print(f"SimpleTileCore line coverage: {percent:.1f}% ({covered}/{total}), minimum {minimum:g}%")
sys.exit(percent < minimum)
PY
