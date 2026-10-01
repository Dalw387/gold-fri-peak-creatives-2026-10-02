#!/usr/bin/env bash
# Concatenate committed chunks into mp4 files.
# encoding=bin  -> raw bytes in bin.* (preferred)
# encoding=b64  -> base64 text in part* (legacy)
set -euo pipefail
shopt -s nullglob

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

found=0
for dir in chunks/*/; do
  meta="${dir}meta.txt"
  if [[ ! -f "$meta" ]]; then
    echo "skip $dir (no meta.txt)"
    continue
  fi

  name=$(grep '^name=' "$meta" | head -n1 | cut -d= -f2-)
  encoding=$(grep '^encoding=' "$meta" | head -n1 | cut -d= -f2- || true)
  if [[ -z "$name" || "$name" == */* ]]; then
    echo "invalid name= in $meta" >&2
    exit 1
  fi
  if [[ -z "$encoding" ]]; then
    encoding=b64
  fi

  found=1
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' RETURN

  case "$encoding" in
    bin)
      mapfile -t pieces < <(printf '%s\n' "$dir"bin.* | sort -V)
      if [[ ${#pieces[@]} -eq 0 || ! -f "${pieces[0]}" ]]; then
        echo "No binary chunks (bin.*) in $dir" >&2
        exit 1
      fi
      cat "${pieces[@]}" > "$tmp"
      ;;
    b64)
      mapfile -t pieces < <(printf '%s\n' "$dir"part* | sort -V)
      if [[ ${#pieces[@]} -eq 0 || ! -f "${pieces[0]}" ]]; then
        echo "No base64 parts (part*) in $dir; refusing to read the chunks directory" >&2
        exit 1
      fi
      # Drop whitespace so wrapped base64 still decodes.
      tr -d '[:space:]' < <(cat "${pieces[@]}") | base64 -d > "$tmp"
      ;;
    *)
      echo "Unknown encoding=$encoding in $meta" >&2
      exit 1
      ;;
  esac

  if ! head -c 32 "$tmp" | grep -a -q ftyp; then
    echo "Assembled $name is not an mp4 (missing ftyp)" >&2
    exit 1
  fi

  if grep -q '^sha256=' "$meta"; then
    want=$(grep '^sha256=' "$meta" | head -n1 | cut -d= -f2-)
    got=$(sha256sum "$tmp" | awk '{print $1}')
    if [[ "$want" != "$got" ]]; then
      echo "sha256 mismatch for $name" >&2
      echo "  want $want" >&2
      echo "  got  $got" >&2
      exit 1
    fi
  fi

  mv "$tmp" "$name"
  trap - RETURN
  echo "Assembled $name ($(wc -c < "$name") bytes) via $encoding"
done

if [[ "$found" -eq 0 ]]; then
  echo "No chunk directories under chunks/" >&2
  exit 1
fi
