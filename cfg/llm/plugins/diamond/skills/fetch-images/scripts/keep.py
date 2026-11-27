"""Keep one image for a catalogue item: convert it to a JPEG and record it.

usage: keep.py [--crop WxH+X+Y] OUT ID RAWFILE CAPTION SOURCE

Writes OUT/img/<id lowercased>-<n>.jpg, at JPEG quality 70 and at most 900px on its longest side, and appends it to
OUT/images/<ID>.json, named by the exact ID, as {"id": ID, "images": [{"file", "caption", "source"}]}, with file
relative to OUT. --crop keeps only the W by H pixels of RAWFILE whose top-left corner is X, Y, before the shrink.
Refuses a bad ID, an empty caption, a SOURCE that isn't an http(s) URL, a file sips can't read, a crop outside it,
and a 5th image for an item; a refusal writes nothing."""
import collections, json, os, re, subprocess, sys, tempfile

MAX_IMAGES, QUALITY, MAX_SIDE = 4, 70, 900
SIPS = "/usr/bin/sips"

Crop = collections.namedtuple("Crop", "width height x y")


def parse_crop(s):
    m = re.fullmatch(r"(\d+)x(\d+)\+(\d+)\+(\d+)", s)
    crop = m and Crop(*map(int, m.groups()))
    if not crop or not crop.width or not crop.height:
        sys.exit(f"bad crop {s!r}: want WxH+X+Y in the source's pixels, e.g. 800x600+0+120")
    return crop


def parse(argv):
    crop = None
    if argv[:1] == ["--crop"] and len(argv) > 1:
        crop, argv = parse_crop(argv[1]), argv[2:]
    if len(argv) != 5:
        sys.exit(__doc__)
    out, item, raw, caption, source = argv
    if not re.fullmatch(r"[A-Za-z]+[0-9]+", item):
        sys.exit(f"bad id {item!r}: want letters then digits, as given, e.g. M7")
    if not caption.strip():
        sys.exit("caption required: name the view")
    if not re.fullmatch(r"https?://[^\s/]+\S*", source):
        sys.exit(f"source {source!r} must be the http(s) page the image came from")
    return crop, out, item, raw, caption.strip(), source


def size(path):
    r = subprocess.run([SIPS, "-g", "pixelWidth", "-g", "pixelHeight", path], capture_output=True, text=True)
    width = re.search(r"pixelWidth: (\d+)", r.stdout)
    height = re.search(r"pixelHeight: (\d+)", r.stdout)
    if r.returncode or not width or not height:
        sys.exit(f"not an image sips can read: {path}")
    return int(width[1]), int(height[1])


def sips(*args):
    r = subprocess.run([SIPS, *map(str, args)], capture_output=True, text=True)
    if r.returncode or not os.path.exists(args[-1]):
        sys.exit(f"sips failed: {r.stderr}{r.stdout}")


def main():
    crop, out, item, raw, caption, source = parse(sys.argv[1:])
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
    width, height = size(raw)
    if crop and (crop.x + crop.width > width or crop.y + crop.height > height):
        sys.exit(f"crop {crop.width}x{crop.height}+{crop.x}+{crop.y} reaches outside the {width}x{height} image")

    with tempfile.TemporaryDirectory() as tmp:
        if crop:
            # sips-316 (macOS 26.6) centres a --cropOffset crop instead when the offset is 0,0, or when x is 0 and the crop
            # reaches the bottom edge. magick crops instead, but reads only what sips wrote, never RAWFILE.
            converted, cropped = os.path.join(tmp, "converted.png"), os.path.join(tmp, "cropped.png")
            sips("-s", "format", "png", raw, "--out", converted)
            r = subprocess.run(["magick", converted, "-crop", f"{crop.width}x{crop.height}+{crop.x}+{crop.y}",
                                "+repage", cropped], capture_output=True, text=True)
            if r.returncode:
                sys.exit(f"magick failed to crop: {r.stderr}")
            raw, width, height = cropped, crop.width, crop.height
        resize = ["-Z", MAX_SIDE] if max(width, height) > MAX_SIDE else []
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        sips("-s", "format", "jpeg", "-s", "formatOptions", QUALITY, *resize, raw, "--out", dest)
    kept["images"].append({"file": file, "caption": caption, "source": source})
    os.makedirs(os.path.dirname(record), exist_ok=True)
    with open(record + ".part", "w", encoding="utf-8") as f:
        json.dump(kept, f, ensure_ascii=False, indent=1)
    os.replace(record + ".part", record)
    print(file)


if __name__ == "__main__":
    main()
