"""Find openly licensed images on Wikimedia Commons.

usage: wikimedia.py search QUERY        File: titles matching QUERY, a line each
       wikimedia.py urls TITLE ...      per File: title, "<1200px rendition URL>\t<Commons page URL>"

Download the renditions with dl.sh; the page URL is the source to keep them with. Retries a 429 or 5xx up to 3
tries, waiting as its Retry-After asks."""
import json, sys, time, urllib.error, urllib.parse, urllib.request

API = "https://commons.wikimedia.org/w/api.php?"
# Wikimedia asks scripts to name themselves rather than pose as a browser.
HEADERS = {"User-Agent": "diamond-research/1.0 (image research script)"}
TRIES, DEFAULT_WAIT, MAX_WAIT = 3, 20, 120


def retry_after(value):
    return min(int(value), MAX_WAIT) if value and value.isdigit() else DEFAULT_WAIT


def query(**params):
    url = API + urllib.parse.urlencode(dict(format="json", action="query", **params))
    for attempt in range(1, TRIES + 1):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=60) as r:
                return json.load(r)["query"]
        except urllib.error.HTTPError as e:
            if not (e.code == 429 or e.code >= 500) or attempt == TRIES:
                raise
            time.sleep(retry_after(e.headers.get("Retry-After")))


def search(text):
    for hit in query(list="search", srnamespace=6, srlimit=10, srsearch=text)["search"]:
        print(hit["title"])


def urls(titles):
    missing = False
    for title in titles:
        page = next(iter(query(titles=title, prop="imageinfo", iiprop="url", iiurlwidth=1200)["pages"].values()))
        if "imageinfo" not in page:
            print(f"missing: {title}", file=sys.stderr)
            missing = True
            continue
        info = page["imageinfo"][0]
        print(info.get("thumburl") or info["url"], info["descriptionurl"], sep="\t")
    return missing


def main(argv):
    if len(argv) == 2 and argv[0] == "search":
        search(argv[1])
    elif len(argv) >= 2 and argv[0] == "urls":
        sys.exit(1 if urls(argv[1:]) else 0)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
