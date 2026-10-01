#!/usr/bin/env bash
# Split one local mp4 into chunks the assemble workflow can rebuild.
# Usage: scripts/chunk-mp4.sh <source.mp4> <dest-dir> <bin|b64>
# Example:
#   scripts/chunk-mp4.sh ~/tiktok-10/TT08.mp4 chunks/TT08 bin
#   scripts/chunk-mp4.sh ~/gold-extra-9/E6.mp4 chunks/E6 b64
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <source.mp4> <dest-dir> <bin|b64>" >&2
  exit 1
fi

src=$1
dest=$2
encoding=$3
name=$(basename "$src")

if [[ ! -f "$src" ]]; then
  echo "Missing source: $src" >&2
  exit 1
fi
if ! head -c 32 "$src" | grep -a -q ftyp; then
  echo "Source is not an mp4: $src" >&2
  exit 1
fi
case "$encoding" in
  bin|b64) ;;
  *) echo "encoding must be bin or b64" >&2; exit 1 ;;
esac

rm -rf "$dest"
mkdir -p "$dest"

sha=$(sha256sum "$src" | awk '{print $1}')

if [[ "$encoding" == "bin" ]]; then
  split -b 200000 -d -a 2 "$src" "$dest/bin."
  parts=$(find "$dest" -name 'bin.*' | wc -l)
else
  tmp=$(mktemp)
  base64 -w 0 "$src" > "$tmp"
  split -b 80000 -d -a 2 "$tmp" "$dest/part."
  rm -f "$tmp"
  parts=$(find "$dest" -name 'part.*' | wc -l)
fi

cat > "$dest/meta.txt" <<EOF
parts=$parts
name=$name
encoding=$encoding
sha256=$sha
EOF

echo "Wrote $parts $encoding chunk(s) for $name in $dest"
