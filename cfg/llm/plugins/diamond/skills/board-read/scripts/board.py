#!/usr/bin/env python3
"""Read what the user drew on an Obsidian Excalidraw board.

usage: board.py {inventory,text,clusters,since,render} BOARD [options]
"""
import argparse, collections, json, math, os, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from boardlib import Board, ROW, bbox, parse_time, slug, stamp, union

GAP = 150
TILE = 3200
OVERLAP = 150
MAP_WIDTH = 800
FONTS = [os.environ.get("BOARD_FONT_BODY"), "/System/Library/Fonts/Hiragino Sans GB.ttc",
         "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]


def at(e):
    return f"[{round(e['x'])},{round(e['y'])}]"


def label(c):
    return f"{c.target.kind}:{c.target.name}" if c.target else "nothing to attribute to"


def inventory(b, a):
    print("elements by type:", dict(collections.Counter(e["type"] for e in b.live)))
    print("deleted:", len(b.all) - len(b.live))
    cards = sum(1 for i in b.images if b.card_path(i))
    print(f"images: {len(b.images)}, of which {cards} are cards found in {b.cards_dir}")
    print("themes:")
    for r in sorted(b.themes, key=lambda r: (r["y"] // ROW, r["x"])):
        print(f"  {at(r)} {round(r['width'])}x{round(r['height'])} {b.theme_title(r)}")


def text(b, a):
    for t in sorted(b.texts, key=lambda t: (t["y"] // 400, t["x"])):
        print(f"TEXT {at(t)} updated {stamp(t['updated'])}: {t['text']!r}")
    for i in b.images:
        t = b.image_target(i)
        print(f"IMAGE {at(i)} {round(i['width'])}x{round(i['height'])} {t.kind}:{t.name}")
    by_id = {e["id"]: e for e in b.live}

    def end(e, binding):
        other = by_id.get((e.get(binding) or {}).get("elementId"))
        if other is None:
            return "-"
        if other["type"] == "image":
            return b.image_target(other).name
        if other["type"] == "text":
            return repr(other["text"][:30])
        if other["type"] == "rectangle":
            return b.theme_title(other)
        return other["type"]

    for e in b.live:
        if e["type"] in ("arrow", "line"):
            print(f"{e['type'].upper()} {at(e)} {end(e, 'startBinding')} -> {end(e, 'endBinding')} "
                  f"(arrowhead {e.get('endArrowhead')}) updated {stamp(e['updated'])}")


def clusters(b, a):
    found = b.clusters(a.gap)
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        with open(a.out, "w", encoding="utf-8") as f:
            json.dump([c.as_json(cid) for cid, c in found.items()], f, indent=1, ensure_ascii=False)
    print(f"{len(b.strokes)} strokes in {len(found)} clusters (gap {a.gap:g})")
    for cid, c in found.items():
        j = c.as_json(cid)
        print(f"{cid} {j['strokes']:>4} strokes {label(c)} distance {j['distance']} bbox {j['bbox']} "
              f"last {j['last_updated']} also {j['runners_up']}")


def since(b, a):
    changed = [e for e in b.live if e["updated"] > a.time]
    others = [e for e in changed if e["type"] != "freedraw"]
    deleted = sum(1 for e in b.all if e.get("isDeleted") and e["updated"] > a.time)
    print(f"since {stamp(a.time)}: {len(changed)} live elements updated, {len(others)} of them not strokes; "
          f"{deleted} deleted (ignored)")
    for e in others:
        what = (repr(e["text"][:80]) if e["type"] == "text" else
                b.image_target(e).name if e["type"] == "image" else
                b.theme_title(e) if e["type"] == "rectangle" else "")
        print(f"  {e['type']} {at(e)} {stamp(e['updated'])} {what}")
    new = {e["id"] for e in changed}
    print("clusters holding new strokes:")
    for cid, c in b.clusters(a.gap).items():
        n = sum(1 for s in c.strokes if s["id"] in new)
        if n:
            print(f"  {cid} {label(c)} {n}/{len(c.strokes)} new")


def mvg_string(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


class Canvas:
    """A crop of the board, `box` in canvas units, drawn `width` pixels wide with ImageMagick's MVG."""

    def __init__(self, b, font, box, width, strokes, cards=True, stroke_scale=1.5, tiles=()):
        self.b, self.font, self.box, self.cards, self.stroke_scale = b, font, box, cards, stroke_scale
        self.strokes = [e for e in strokes if self.shows(e)]
        self.tiles = tiles
        self.s = width / (box[2] - box[0])
        self.size = (round(width), max(1, round((box[3] - box[1]) * self.s)))

    def shows(self, e):
        x0, y0, x1, y1 = bbox(e)
        return x0 < self.box[2] and x1 > self.box[0] and y0 < self.box[3] and y1 > self.box[1]

    def p(self, x, y):
        return f"{(x - self.box[0]) * self.s:.1f},{(y - self.box[1]) * self.s:.1f}"

    def rect(self, e):
        return f"rectangle {self.p(e['x'], e['y'])} {self.p(e['x'] + e['width'], e['y'] + e['height'])}"

    def words(self, x, y, size, color, s):
        return f"font {mvg_string(self.font)} fill '{color}' stroke none font-size {size:.0f} text {self.p(x, y)} {mvg_string(s)}"

    def mvg(self):
        b, s, out = self.b, self.s, []
        for r in b.rects:
            if self.shows(r):
                out.append(f"stroke '#c9a66b' stroke-width 3 fill '#fbf6ea' {self.rect(r)}")
        for i in b.images:
            if not self.shows(i):
                continue
            path = b.card_path(i)
            if path and self.cards:
                out.append(f"image over {self.p(i['x'], i['y'])} {i['width'] * s:.0f},{i['height'] * s:.0f} {mvg_string(path)}")
                out.append(f"fill '#ffffffc8' stroke none {self.rect(i)}")
            else:
                out.append(f"stroke '#999' fill '#eee' {self.rect(i)}")
            size = max(16, 70 * s)
            out.append(self.words(i["x"] + 4 / s, i["y"] + size / s, size, "#1a5fb4", b.image_target(i).name))
        for t in b.texts:
            if self.shows(t):
                size = max(11, min(t["fontSize"], 60) * s)
                for n, line in enumerate(t["text"].split("\n")[:8], 1):
                    out.append(self.words(t["x"], t["y"] + size * n * 1.2 / s, size, "#b0413e", line[:80]))
        for e in b.live:
            if e["type"] in ("arrow", "line") and self.shows(e):
                out.append("stroke '#2a7' stroke-width 3 fill none polyline " +
                           " ".join(self.p(e["x"] + x, e["y"] + y) for x, y in e["points"]))
        for e in self.strokes:
            width = max(1.4, e.get("strokeWidth", 2) * self.stroke_scale * s)
            out.append(f"stroke '#000' stroke-width {width:.1f} fill none stroke-linecap round stroke-linejoin round "
                       "polyline " + " ".join(self.p(e["x"] + x, e["y"] + y) for x, y in e["points"]))
        for k, t in enumerate(self.tiles, 1):
            out.append(f"stroke '#c01c28' stroke-width 3 fill none rectangle {self.p(t[0], t[1])} {self.p(t[2], t[3])}")
            out.append(self.words(t[0] + 10 / self.s, t[1] + 40 / self.s, 32, "#c01c28", f"{k}"))
        return "\n".join(out)

    def save(self, path):
        with tempfile.NamedTemporaryFile("w", suffix=".mvg", encoding="utf-8", delete=False) as f:
            f.write(self.mvg())
        try:
            subprocess.run(["magick", "-size", f"{self.size[0]}x{self.size[1]}", "xc:white", "-draw", "@" + f.name, path],
                           check=True)
        finally:
            os.remove(f.name)
        return path


def pad(box, m):
    return (box[0] - m, box[1] - m, box[2] + m, box[3] + m)


def tiles(box, size, overlap=OVERLAP):
    """`box` cut into equal tiles at most `size` across, row by row; neighbours overlap by `overlap`."""
    x0, y0, x1, y1 = box
    cols, rows = math.ceil((x1 - x0) / size), math.ceil((y1 - y0) / size)
    w, h, half = (x1 - x0) / cols, (y1 - y0) / rows, overlap / 2
    return [(max(x0, x0 + c * w - half), max(y0, y0 + r * h - half),
             min(x1, x0 + (c + 1) * w + half), min(y1, y0 + (r + 1) * h + half))
            for r in range(rows) for c in range(cols)]


def crop_width(box, width):
    return min(width, max(600, box[2] - box[0]))


def render(b, a):
    # ImageMagick draws no text at all without a font file
    font = next((f for f in FONTS if f and os.path.isfile(f)), None)
    if font is None:
        sys.exit("board-read: no font found; set BOARD_FONT_BODY to a .ttf or .ttc file")
    found = b.clusters(a.gap)
    unknown = set(a.only or ()) - set(found)
    if unknown:
        sys.exit(f"board-read: no such clusters: {' '.join(sorted(unknown))}")
    os.makedirs(a.out, exist_ok=True)
    done = []
    for cid, c in found.items():
        if a.only and cid not in a.only:
            continue
        box = pad(c.bbox, 80)
        if c.target:
            box = union(box, pad(c.target.bbox, 40))
        parts = tiles(box, a.tile)
        name = os.path.join(a.out, f"cluster_{cid}")
        if len(parts) == 1:
            done.append(Canvas(b, font, box, crop_width(box, a.width), c.strokes).save(name + ".png"))
            continue
        done.append(Canvas(b, font, box, MAP_WIDTH, c.strokes, cards=False, stroke_scale=3, tiles=parts)
                    .save(name + "_map.png"))
        for k, t in enumerate(parts, 1):
            done.append(Canvas(b, font, t, crop_width(t, a.width), c.strokes)
                        .save(f"{name}_tile{k}of{len(parts)}.png"))
    if not a.only:
        for r in b.themes:
            title = b.theme_title(r)
            mine = [c for c in found.values() if c.target and c.target.kind == "theme" and c.target.name == title]
            box = pad(union(bbox(r), *(c.bbox for c in mine)), 40)
            strokes = [s for c in mine for s in c.strokes]
            done.append(Canvas(b, font, box, a.width, strokes).save(os.path.join(a.out, f"theme_{slug(title)}.png")))
        everything = [bbox(e) for e in b.live]
        if everything:
            done.append(Canvas(b, font, pad(union(*everything), 40), 2400, b.strokes, cards=False, stroke_scale=3)
                        .save(os.path.join(a.out, "overview.png")))
    print("\n".join(done))


def time_arg(s):
    try:
        return parse_time(s)
    except ValueError as e:
        raise argparse.ArgumentTypeError(str(e))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    commands = dict(inventory=inventory, text=text, clusters=clusters, since=since, render=render)
    for name in commands:
        p = sub.add_parser(name)
        p.add_argument("board")
        p.add_argument("--cards", help="the card images' folder (default: '<board name> cards' beside the board)")
        if name in ("clusters", "since", "render"):
            p.add_argument("--gap", type=float, default=GAP, help=f"canvas units between strokes of one cluster ({GAP})")
        if name == "clusters":
            p.add_argument("--out", help="also write the clusters as JSON to this file")
        if name == "since":
            p.add_argument("time", type=time_arg, help="local time 'YYYY-MM-DD HH:MM', or epoch milliseconds")
        if name == "render":
            p.add_argument("--out", required=True, help="folder for the PNGs")
            p.add_argument("--width", type=int, default=1600, help="widest crop, in pixels (1600)")
            p.add_argument("--tile", type=float, default=TILE,
                           help=f"canvas units across a crop before a cluster is cut into tiles ({TILE})")
            p.add_argument("--only", nargs="+", metavar="ID", help="render only these clusters (M7@1200,-340 ...)")
    a = ap.parse_args()
    try:
        b = Board(a.board, a.cards)
    except (OSError, ValueError) as e:
        sys.exit(f"board-read: {e}")
    commands[a.cmd](b, a)


if __name__ == "__main__":
    main()
