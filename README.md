# Gold Fri peak creatives

Temporary public host for Postiz ingest. Safe to delete after 2026-10-03.

## Assemble

`chunks/<id>/` holds either raw binary pieces (`encoding=bin`, files `bin.00`…) or legacy base64 text (`encoding=b64`, files `part.00`…). `scripts/assemble.sh` concatenates them, checks the mp4 `ftyp` header and the `sha256` in `meta.txt`, and writes `<name>` at the repo root.

The GitHub Action runs that script on pushes that touch `chunks/**`.

## Regenerate from the local box

Working masters live locally under `tiktok-10/` (TT01–TT10) and `gold-extra-9/` (E1–E9). This repo does not have those directories. From a checkout:

```bash
scripts/chunk-mp4.sh /path/to/tiktok-10/TT08.mp4 chunks/TT08 bin
scripts/chunk-mp4.sh /path/to/gold-extra-9/E6.mp4 chunks/E6 b64
bash scripts/assemble.sh
```

Commit the new `chunks/` directory (and the assembled mp4 if you want the public file in the same commit). Prefer `bin` chunks. Use `b64` only when a text-only upload is required.

Cloud copies already matched and committed: TT01–TT07 and E1 (Google Drive folder `GoldFriPeak20261002`). TT08–TT10 and E2–E9 were not in that folder, so they are not guessed into this repo.
