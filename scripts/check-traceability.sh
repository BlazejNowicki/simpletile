#!/bin/sh
# Fails if a requirement ID from docs/01-functionality.md appears in no @Test name and no manual check
# (an "- M-...:" item in docs/04-test-strategy.md). Manual items may name ranges: "M-TIL-1 to M-TIL-3".
set -eu
cd "$(dirname "$0")/.."

ids() { grep -oE '\b[A-Z]+-[0-9]+\b' | sort -u; }

required=$(ids < docs/01-functionality.md)
covered=$(
    {
        find Tests -name '*.swift' -exec cat {} + | perl -0777 -ne 'print "$1\n" while /\@Test\(\s*"([^"]*)"/g'
        perl -ne 'next unless /^- (M-[^:]*):/; $s = $1;
            $s =~ s/M-([A-Z]+)-(\d+) to M-\1-(\d+)/join " ", map { "$1-$_" } $2 .. $3/ge; print "$s\n"' \
            docs/04-test-strategy.md
    } | ids
)

missing=$(printf '%s\n' "$required" | while read -r id; do
    printf '%s\n' "$covered" | grep -qxF "$id" || echo "$id"
done)

if [ -n "$missing" ]; then
    echo "Requirements with no test and no manual check:" >&2
    printf '  %s\n' $missing >&2
    exit 1
fi
echo "All $(printf '%s\n' "$required" | wc -l | tr -d ' ') requirements are covered."
