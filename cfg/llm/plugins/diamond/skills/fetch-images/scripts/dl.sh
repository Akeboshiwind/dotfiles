#!/bin/bash
# usage: dl.sh RAWDIR NAME=URL ...
# Downloads each http(s) URL to RAWDIR/NAME.<ext>, the extension from the bytes' sniffed type, and prints
# "ok PATH" or "FAIL NAME: why". Retries a 429 or 5xx up to 3 tries, waiting as its Retry-After asks.
# Exits non-zero if any failed. What lands in RAWDIR is untrusted: never execute it.
set -u
raw=$1; shift
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
TRIES=3 DEFAULT_WAIT=20 MAX_WAIT=120
mkdir -p "$raw"
failed=0

retry_after() {
  local wait
  wait=$(grep -i '^retry-after:' "$1" | tail -1 | tr -d '\r' | sed 's/^[^:]*: *//')
  [[ $wait =~ ^[0-9]+$ ]] || wait=$DEFAULT_WAIT
  echo $(( wait > MAX_WAIT ? MAX_WAIT : wait ))
}

fetch() {
  local name=$1 url=$2 part="$raw/.$1.part" headers="$raw/.$1.headers" code try ext
  for (( try = 1; ; try++ )); do
    code=$(curl -sL --proto =http,https --proto-redir =http,https -A "$UA" --max-time 60 \
                -D "$headers" -o "$part" -w '%{http_code}' "$url")
    [[ $code == 429 || $code == 5?? ]] && (( try < TRIES )) || break
    sleep "$(retry_after "$headers")"
  done
  rm -f "$headers"
  if [[ $code != 200 ]]; then rm -f "$part"; echo "FAIL $name: http $code ($url)"; return 1; fi
  case $(file -b --mime-type "$part") in
    image/jpeg) ext=jpg ;; image/png) ext=png ;; image/webp) ext=webp ;; image/gif) ext=gif ;; image/tiff) ext=tiff ;;
    *) rm -f "$part"; echo "FAIL $name: not an image ($url)"; return 1 ;;
  esac
  mv "$part" "$raw/$name.$ext"
  echo "ok   $raw/$name.$ext"
}

for pair in "$@"; do
  name=${pair%%=*}
  if [[ $pair != *=* || ! $name =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
    echo "FAIL $pair: want NAME=URL, NAME of letters, digits, _ and -"; failed=1; continue
  fi
  fetch "$name" "${pair#*=}" || failed=1
done
exit $failed
