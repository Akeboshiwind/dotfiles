#!/bin/bash
# usage: search-app.sh TERM
# The iTunes Search API's top 5 iOS apps for TERM, a line each: "<app id>\t<name>\t<seller>".
set -euo pipefail
curl -sfL -G --max-time 30 "https://itunes.apple.com/search" \
     --data-urlencode "term=$1" -d media=software -d entity=software -d limit=5 |
python3 -I -c '
import json, sys
for r in json.load(sys.stdin)["results"]:
    print(r["trackId"], r["trackName"], r.get("sellerName", ""), sep="\t")'
