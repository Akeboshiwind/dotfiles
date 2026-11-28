#!/usr/bin/env python3
"""Read what the user drew on an Obsidian Excalidraw board.

usage: board.py {inventory,text,clusters,snapshot,since,render} BOARD [options]
"""
import argparse, collections, datetime, json, math, os, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from boardlib import SUFFIX, Board, bbox, parse_time, slug, stamp, union

GAP = 150
TILE = 3200
OVERLAP = 150
MAP_WIDTH = 800
NUDGE = 0.5  # canvas units an element can shift before it counts as moved
FONTS = [os.environ.get("BOARD_FONT_BODY"), "/System/Library/Fonts/Hiragino Sans GB.ttc",
         "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]


def at(e):
    return f"[{round(e['x'])},{round(e['y'])}]"


def label(c):
    return str(c.target) if c.target else "nothing to attribute to"


def inventory(b, a):
    print("elements by type:", dict(collections.Counter(e["type"] for e in b.live)))
    print("deleted:", len(b.all) - len(b.live))
    cards = sum(1 for i in b.images if b.card_path(i))
    print(f"images: {len(b.images)}, of which {cards} are cards found in {b.cards_dir}")
    print("themes:")
    for t in b.themes.values():
        x0, y0, x1, y1 = t.bbox
        print(f"  [{round(x0)},{round(y0)}] {round(x1 - x0)}x{round(y1 - y0)} {t.name}")


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
            return b.rect_name(other)
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
        print(f"{cid} {j['strokes']:>4} strokes {label(c)} distance {j['distance']} section {j['section']!r} "
              f"bbox {j['bbox']} last {j['last_updated']} also {j['runners_up']}")
    for cid, c in found.items():
        if c.flags:
            print(f"AMBIGUOUS {cid}: {'; '.join(map(str, c.flags))}")


def since(b, a):
    if a.time is None:
        since_snapshot(b, a)
    elif a.snapshot:
        sys.exit("board-read: give a time or --snapshot, not both")
    else:
        since_time(b, a)


def since_time(b, a):
    changed = [e for e in b.live if e["updated"] > a.time]
    others = [e for e in changed if e["type"] != "freedraw"]
    deleted = sum(1 for e in b.all if e.get("isDeleted") and e["updated"] > a.time)
    print(f"since {stamp(a.time)}, by `updated` (a dragged card counts): {len(changed)} live elements updated, "
          f"{len(others)} of them not strokes; {deleted} deleted (ignored)")
    for e in others:
        what = (repr(e["text"][:80]) if e["type"] == "text" else
                b.image_target(e).name if e["type"] == "image" else
                b.rect_name(e) if e["type"] == "rectangle" else "")
        print(f"  {e['type']} {at(e)} {stamp(e['updated'])} {what}")
    new = {e["id"] for e in changed}
    print("clusters holding new strokes:")
    for cid, c in b.clusters(a.gap).items():
        n = sum(1 for s in c.strokes if s["id"] in new)
        if n:
            print(f"  {cid} {label(c)} {n}/{len(c.strokes)} new")


def state_dir(a):
    root = a.state_dir or os.environ.get("DIAMOND_STATE_DIR") or os.path.expanduser("~/.local/state/diamond")
    return os.path.join(root, os.path.basename(a.board)[:-len(SUFFIX)])


def what(b, e):
    if e["type"] == "image":
        return str(b.image_target(e))
    if e["type"] == "text":
        return f"text {e['text'][:60]!r}"
    if e["type"] == "rectangle":
        return str(b.themes[e["id"]]) if e["id"] in b.themes else f"rectangle {b.rect_name(e)}"
    if e["type"] == "frame":
        return f"frame {e.get('name') or 'untitled'}"
    return e["type"]


def take(b, found):
    """What a later `since` compares against: no `updated` times, which move when a card is only dragged."""
    return dict(
        elements={e["id"]: dict(what=what(b, e), x=e["x"], y=e["y"], width=e["width"], height=e["height"],
                                text=e.get("text"), file=b.files.get(e.get("fileId")))
                  for e in b.live if e["type"] != "freedraw"},
        strokes={s["id"]: [s["x"], s["y"]] for s in b.strokes},
        clusters=[dict(id=cid, what=label(c), stroke_ids=[s["id"] for s in c.strokes]) for cid, c in found.items()])


def snapshot(b, a):
    folder = state_dir(a)
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, datetime.datetime.now().strftime("%Y-%m-%dT%H-%M-%S") + ".json")
    taken = take(b, b.clusters(a.gap))
    with open(path, "w", encoding="utf-8") as f:
        json.dump(taken, f)
    print(f"snapshot {path}: {len(taken['elements'])} elements, {len(taken['strokes'])} strokes")


def latest_snapshot(a):
    folder, prefix = state_dir(a), (a.snapshot or "").replace(":", "-")
    names = os.listdir(folder) if os.path.isdir(folder) else []
    found = sorted(n for n in names if n.endswith(".json") and n.startswith(prefix))
    if not found:
        sys.exit(f"board-read: no snapshot named {prefix}* in {folder}; run `snapshot` after a read, or give a time")
    return os.path.join(folder, found[-1])


def shifted(p, q):
    return abs(p - q) > NUDGE


def element_changes(old, new):
    for eid, e in new.items():
        o = old.get(eid)
        if o is None:
            yield f"ADDED {e['what']} at [{round(e['x'])},{round(e['y'])}]"
            continue
        if shifted(o["x"], e["x"]) or shifted(o["y"], e["y"]):
            yield f"MOVED {e['what']} by ({round(e['x'] - o['x'])},{round(e['y'] - o['y'])})"
        if shifted(o["width"], e["width"]) or shifted(o["height"], e["height"]):
            yield (f"RESIZED {e['what']} {round(o['width'])}x{round(o['height'])} -> "
                   f"{round(e['width'])}x{round(e['height'])}")
        if o["text"] != e["text"]:
            yield f"TEXT {e['what']} was {o['text'][:60]!r}"
        if o["file"] != e["file"]:
            yield f"FILE {e['what']} was {o['file']}"
    for eid, o in old.items():
        if eid not in new:
            yield f"REMOVED {o['what']} at [{round(o['x'])},{round(o['y'])}]"


def stroke_changes(old, new, found):
    """Each change counted under the current cluster that holds it, keyed on stroke ids, never on a cluster's ID.

    A removed stroke counts under the current cluster holding most of what is left of its cluster at the snapshot.
    """
    added = new["strokes"].keys() - old["strokes"].keys()
    removed = old["strokes"].keys() - new["strokes"].keys()
    moved = {i for i in new["strokes"].keys() & old["strokes"].keys()
             if any(map(shifted, old["strokes"][i], new["strokes"][i]))}
    yield f"strokes: {len(added)} added, {len(removed)} removed, {len(moved)} moved"
    owner = {s["id"]: cid for cid, c in found.items() for s in c.strokes}
    counts = collections.defaultdict(collections.Counter)
    for i in added:
        counts[owner[i]]["added"] += 1
    for i in moved:
        counts[owner[i]]["moved"] += 1
    orphans = []
    for c in old["clusters"]:
        lost = sum(1 for i in c["stroke_ids"] if i in removed)
        heirs = collections.Counter(owner[i] for i in c["stroke_ids"] if i in owner)
        if lost and heirs:
            counts[min(heirs, key=lambda cid: (-heirs[cid], cid))]["removed"] += lost
        elif lost:
            orphans.append(f"  {lost} removed with all of {c['id']} {c['what']} (its ID at the snapshot)")
    for cid, c in found.items():
        if cid in counts:
            n = counts[cid]
            yield (f"  {cid} {label(c)}: " + ", ".join(f"{n[k]} {k}" for k in ("added", "removed", "moved") if n[k])
                   + f" (of {len(c.strokes)} now)")
    yield from orphans


def refilings(old, found):
    now = {frozenset(s["id"] for s in c.strokes): (cid, c) for cid, c in found.items()}
    for o in old["clusters"]:
        cid, c = now.get(frozenset(o["stroke_ids"]), (None, None))
        if c and label(c) != o["what"]:
            yield f"  REFILED {o['id']} -> {cid}"


def since_snapshot(b, a):
    path = latest_snapshot(a)
    with open(path, encoding="utf-8") as f:
        old = json.load(f)
    found = b.clusters(a.gap)
    new = take(b, found)
    print(f"since snapshot {os.path.basename(path)[:-len('.json')]}, by position, size, text and file "
          "(a dragged card is MOVED, not a note):")
    print("\n".join(f"  {line}" for line in element_changes(old["elements"], new["elements"]))
          or "  no element changes")
    print("\n".join([*stroke_changes(old, new, found), *refilings(old, found)]))


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
        return overlaps(bbox(e), self.box)

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


def overlaps(a, b):
    return a[0] < b[2] and a[2] > b[0] and a[1] < b[3] and a[3] > b[1]


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
        if c.target and not c.far:
            box = union(box, pad(c.target.bbox, 40))
        parts = [t for t in tiles(box, a.tile) if any(overlaps(bbox(s), t) for s in c.strokes)]
        name = os.path.join(a.out, f"cluster_{cid}")
        if len(parts) == 1:
            done.append(Canvas(b, font, parts[0], crop_width(parts[0], a.width), c.strokes).save(name + ".png"))
            continue
        done.append(Canvas(b, font, box, MAP_WIDTH, c.strokes, cards=False, stroke_scale=3, tiles=parts)
                    .save(name + "_map.png"))
        for k, t in enumerate(parts, 1):
            done.append(Canvas(b, font, t, crop_width(t, a.width), c.strokes)
                        .save(f"{name}_tile{k}of{len(parts)}.png"))
    if not a.only:
        for theme in b.themes.values():
            mine = [c for c in found.values() if c.target == theme and not c.far]
            box = pad(union(theme.bbox, *(c.bbox for c in mine)), 40)
            strokes = [s for c in mine for s in c.strokes]
            done.append(Canvas(b, font, box, a.width, strokes).save(os.path.join(a.out, f"theme_{slug(theme.name)}.png")))
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
    commands = dict(inventory=inventory, text=text, clusters=clusters, snapshot=snapshot, since=since,
                    render=render)
    for name in commands:
        p = sub.add_parser(name)
        p.add_argument("board")
        p.add_argument("--cards", help="the card images' folder (default: '<board name> cards' beside the board)")
        if name in ("clusters", "snapshot", "since", "render"):
            p.add_argument("--gap", type=float, default=GAP, help=f"canvas units between strokes of one cluster ({GAP})")
        if name == "clusters":
            p.add_argument("--out", help="also write the clusters as JSON to this file")
        if name in ("snapshot", "since"):
            p.add_argument("--state-dir",
                           help="snapshots' root (default: $DIAMOND_STATE_DIR, else ~/.local/state/diamond)")
        if name == "since":
            p.add_argument("time", nargs="?", type=time_arg,
                           help="local time 'YYYY-MM-DD HH:MM', or epoch milliseconds: compares `updated` instead")
            p.add_argument("--snapshot", metavar="PREFIX", help="the latest snapshot whose name starts so (default: latest)")
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
