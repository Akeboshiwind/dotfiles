#!/bin/bash
# usage: itunes.sh APP_ID
# An App Store app's screenshots at full size, from the iTunes Lookup API: "page <App Store URL>", then
# "phone <url>" per screenshotUrls entry and "ipad <url>" per ipadScreenshotUrls entry. The app's name goes to stderr.
set -euo pipefail
[[ ${1:-} =~ ^[0-9]+$ ]] || { echo "usage: itunes.sh APP_ID (digits, from search-app.sh)" >&2; exit 2; }
curl -sfL --max-time 30 "https://itunes.apple.com/lookup?id=$1" |
python3 -I -c '
import json, re, sys
results = json.load(sys.stdin)["results"]
if not results:
    sys.exit("no app with that id")
app = results[0]
print(app["trackName"], file=sys.stderr)
print("page", app["trackViewUrl"].split("?")[0])
for key, kind in (("screenshotUrls", "phone"), ("ipadScreenshotUrls", "ipad")):
    for url in app.get(key, []):
        print(kind, re.sub(r"/\d+x\d+bb\.(png|jpe?g)$", r"/1800x1800bb.\1", url))'
