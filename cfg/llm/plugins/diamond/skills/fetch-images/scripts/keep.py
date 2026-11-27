"""Keep one image for a catalogue item: convert it to a JPEG and record it.

usage: keep.py OUT ID RAWFILE CAPTION SOURCE

Writes OUT/img/<id lowercased>-<n>.jpg, at JPEG quality 70 and at most 900px on its longest side, and appends it to
OUT/images/<ID>.json, named by the exact ID, as {"id": ID, "images": [{"file", "caption", "source"}]}, with file
relative to OUT. Refuses a bad ID, an empty caption, a SOURCE that isn't an http(s) URL, a file sips can't read,
and a 5th image for an item; a refusal writes nothing."""
import json, os, re, subprocess, sys

MAX_IMAGES, QUALITY, MAX_SIDE = 4, 70, 900
SIPS = "/usr/bin/sips"


def parse(argv):
    if len(argv) != 5:
        sys.exit(__doc__)
    out, item, raw, caption, source = argv
    if not re.fullmatch(r"[A-Za-z]+[0-9]+", item):
        sys.exit(f"bad id {item!r}: want letters then digits, as given, e.g. M7")
    if not caption.strip():
        sys.exit("caption required: name the view")
    if not re.fullmatch(r"https?://[^\s/]+\S*", source):
        sys.exit(f"source {source!r} must be the http(s) page the image came from")
    return out, item, raw, caption.strip(), source


def longest_side(path):
    r = subprocess.run([SIPS, "-g", "pixelWidth", "-g", "pixelHeight", path], capture_output=True, text=True)
    sides = re.findall(r"pixel(?:Width|Height): (\d+)", r.stdout)
    if r.returncode or len(sides) != 2:
        sys.exit(f"not an image sips can read: {path}")
    return max(map(int, sides))


def main():
    out, item, raw, caption, source = parse(sys.argv[1:])
    record = os.path.join(out, "images", f"{item}.json")
    kept = {"id": item, "images": []}
    if os.path.exists(record):
        with open(record, encoding="utf-8") as f:
            kept = json.load(f)
    if kept["id"] != item:
        sys.exit(f"{record} records id {kept['id']!r}, not {item!r}")
    if len(kept["images"]) >= MAX_IMAGES:
        sys.exit(f"{item} already has {MAX_IMAGES} images")
    file = f"img/{item.lower()}-{len(kept['images']) + 1}.jpg"
    dest = os.path.join(out, file)
    if os.path.exists(dest):
        sys.exit(f"{dest} already exists, but {record} doesn't list it")
    resize = ["-Z", str(MAX_SIDE)] if longest_side(raw) > MAX_SIDE else []

    os.makedirs(os.path.dirname(dest), exist_ok=True)
    r = subprocess.run([SIPS, "-s", "format", "jpeg", "-s", "formatOptions", str(QUALITY), *resize, raw, "--out", dest],
                       capture_output=True, text=True)
    if r.returncode or not os.path.exists(dest):
        sys.exit(f"sips failed: {r.stderr}{r.stdout}")
    kept["images"].append({"file": file, "caption": caption, "source": source})
    os.makedirs(os.path.dirname(record), exist_ok=True)
    with open(record + ".part", "w", encoding="utf-8") as f:
        json.dump(kept, f, ensure_ascii=False, indent=1)
    os.replace(record + ".part", record)
    print(file)


if __name__ == "__main__":
    main()
