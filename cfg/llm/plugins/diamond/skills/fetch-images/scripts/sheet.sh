#!/bin/bash
# usage: sheet.sh RAWDIR SHEETDIR [COLS]
# Makes contact sheets of RAWDIR's images, 20 a sheet, each labelled with its file name, as SHEETDIR/sheet-<n>.jpg,
# and prints their paths. Files sips can't read are named on stderr and left out.
# Only sips reads RAWDIR; montage reads only sips' thumbnails, and labels are cut to safe characters.
set -eu
raw=$1 sheets=$2 cols=${3:-5}
[[ $cols =~ ^[1-9][0-9]?$ ]] || { echo "COLS must be 1-99" >&2; exit 2; }
font=
for f in "${BOARD_FONT_BODY:-}" "/System/Library/Fonts/Hiragino Sans GB.ttc" /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf; do
  [[ -n $f && -f $f ]] && { font=$f; break; }
done
[[ -n $font ]] || { echo "no font for labels: set BOARD_FONT_BODY to a .ttf or .ttc file" >&2; exit 2; }

thumbs=$(mktemp -d)
trap 'rm -rf "$thumbs"' EXIT
labelled=()
n=0
for f in "$raw"/*; do
  [[ -f $f ]] || continue
  n=$((n + 1)); thumb=$(printf '%s/%04d.jpg' "$thumbs" "$n")
  if /usr/bin/sips -s format jpeg -Z 400 "$f" --out "$thumb" >/dev/null 2>&1; then
    labelled+=(-label "$(basename "$f" | tr -c 'A-Za-z0-9._\n-' _)" "$thumb")
  else
    echo "unreadable: $f" >&2
  fi
done
(( ${#labelled[@]} )) || { echo "no images in $raw" >&2; exit 1; }

mkdir -p "$sheets"
rm -f "$sheets"/sheet-*.jpg
per_sheet=20 args_per_image=3
args_per_sheet=$((per_sheet * args_per_image))
for (( i = 0, s = 1; i < ${#labelled[@]}; i += args_per_sheet, s++ )); do
  magick montage -font "$font" "${labelled[@]:i:args_per_sheet}" -tile "${cols}x" -geometry 300x300+4+4 "$sheets/sheet-$s.jpg"
  echo "$sheets/sheet-$s.jpg"
done
